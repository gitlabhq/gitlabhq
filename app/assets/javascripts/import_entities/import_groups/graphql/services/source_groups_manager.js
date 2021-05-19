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
      return Object.fromEntries(
        Object.entries(JSON.parse(this.storage.getItem(KEY)) ?? {}).map(([jobId, config]) => {
          // new format of storage
          if (config.groups) {
            return [jobId, config];
          }

          return [
            jobId,
            {
              status: config.status,
              groups: [{ id: config.id, importTarget: config.importTarget }],
            },
          ];
        }),
      );
    } catch {
      return {};
    }
  }

  createImportState(importId, jobConfig) {
    this.importStates[this.getStorageKey(importId)] = {
      status: jobConfig.status,
      groups: jobConfig.groups.map((g) => ({ importTarget: g.import_target, id: g.id })),
    };
    this.saveImportStatesToStorage();
  }

  updateImportProgress(importId, status) {
    const currentState = this.importStates[this.getStorageKey(importId)];
    if (!currentState) {
      return;
    }

    currentState.status = status;
    this.saveImportStatesToStorage();
  }

  getImportStateFromStorageByGroupId(groupId) {
    const PREFIX = this.getStorageKey('');
    const [jobId, importState] =
      Object.entries(this.importStates).find(
        ([key, state]) => key.startsWith(PREFIX) && state.groups.some((g) => g.id === groupId),
      ) ?? [];

    if (!jobId) {
      return null;
    }

    const group = importState.groups.find((g) => g.id === groupId);
    return { jobId, importState: { ...group, status: importState.status } };
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
