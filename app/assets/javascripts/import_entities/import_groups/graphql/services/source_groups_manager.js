import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import produce from 'immer';
import { debounce, merge } from 'lodash';
import { STATUSES } from '../../../constants';
import ImportSourceGroupFragment from '../fragments/bulk_import_source_group_item.fragment.graphql';

function extractTypeConditionFromFragment(fragment) {
  return fragment.definitions[0]?.typeCondition.name.value;
}

function generateGroupId(id) {
  return defaultDataIdFromObject({
    __typename: extractTypeConditionFromFragment(ImportSourceGroupFragment),
    id,
  });
}

export const KEY = 'gl-bulk-imports-import-state';
export const DEBOUNCE_INTERVAL = 200;

export class SourceGroupsManager {
  constructor({ client, sourceUrl, storage = window.localStorage }) {
    this.client = client;
    this.sourceUrl = sourceUrl;

    this.storage = storage;
    this.importStates = this.loadImportStatesFromStorage();
  }

  loadImportStatesFromStorage() {
    try {
      return JSON.parse(this.storage.getItem(KEY)) ?? {};
    } catch {
      return {};
    }
  }

  findById(id) {
    const cacheId = generateGroupId(id);
    return this.client.readFragment({ fragment: ImportSourceGroupFragment, id: cacheId });
  }

  update(group, fn) {
    this.client.writeFragment({
      fragment: ImportSourceGroupFragment,
      id: generateGroupId(group.id),
      data: produce(group, fn),
    });
  }

  updateById(id, fn) {
    const group = this.findById(id);
    this.update(group, fn);
  }

  saveImportState(importId, group) {
    this.importStates[this.getStorageKey(importId)] = {
      id: group.id,
      importTarget: group.import_target,
      status: group.status,
    };
    this.saveImportStatesToStorage();
  }

  getImportStateFromStorage(importId) {
    return this.importStates[this.getStorageKey(importId)];
  }

  getImportStateFromStorageByGroupId(groupId) {
    const PREFIX = this.getStorageKey('');
    const [, importState] =
      Object.entries(this.importStates).find(
        ([key, group]) => key.startsWith(PREFIX) && group.id === groupId,
      ) ?? [];

    return importState;
  }

  getStorageKey(importId) {
    return `${this.sourceUrl}|${importId}`;
  }

  saveImportStatesToStorage = debounce(() => {
    try {
      // storage might be changed in other tab so fetch first
      this.storage.setItem(
        KEY,
        JSON.stringify(merge({}, this.loadImportStatesFromStorage(), this.importStates)),
      );
    } catch {
      // empty catch intentional: storage might be unavailable or full
    }
  }, DEBOUNCE_INTERVAL);

  startImport({ group, importId }) {
    this.setImportStatus(group, STATUSES.CREATED);
    this.saveImportState(importId, group);
  }

  setImportStatus(group, status) {
    this.update(group, (sourceGroup) => {
      // eslint-disable-next-line no-param-reassign
      sourceGroup.status = status;
    });
  }

  setImportStatusByImportId(importId, status) {
    const importState = this.getImportStateFromStorage(importId);
    if (!importState) {
      return;
    }

    if (importState.status !== status) {
      importState.status = status;
    }

    const group = this.findById(importState.id);
    if (group?.id) {
      this.setImportStatus(group, status);
    }

    this.saveImportStatesToStorage();
  }
}
