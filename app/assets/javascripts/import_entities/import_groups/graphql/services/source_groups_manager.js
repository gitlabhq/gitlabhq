import { debounce, merge } from 'lodash';

export const KEY = 'gl-bulk-imports-import-state';
export const DEBOUNCE_INTERVAL = 200;

export class SourceGroupsManager {
  constructor({ sourceUrl, storage = window.localStorage }) {
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

  saveImportState(importId, group) {
    const key = this.getStorageKey(importId);
    const oldState = this.importStates[key] ?? {};

    if (!oldState.id && !group.id) {
      return;
    }

    this.importStates[key] = {
      ...oldState,
      ...group,
      status: group.status,
    };
    this.saveImportStatesToStorage();
  }

  getImportStateFromStorageByGroupId(groupId) {
    const PREFIX = this.getStorageKey('');
    const [jobId, importState] =
      Object.entries(this.importStates).find(
        ([key, group]) => key.startsWith(PREFIX) && group.id === groupId,
      ) ?? [];

    return { jobId, importState };
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
}
