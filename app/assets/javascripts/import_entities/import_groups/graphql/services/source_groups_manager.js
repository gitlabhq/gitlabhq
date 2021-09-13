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
    this.importStates[importId] = {
      status: jobConfig.status,
      groups: jobConfig.groups.map((g) => ({
        importTarget: { ...g.import_target },
        id: g.id,
      })),
    };
    this.saveImportStatesToStorage();
  }

  updateImportProgress(importId, status) {
    const currentState = this.importStates[importId];
    if (!currentState) {
      return;
    }

    currentState.status = status;
    this.saveImportStatesToStorage();
  }

  getImportedGroupsByJobId(jobId) {
    return this.importStates[jobId]?.groups ?? [];
  }

  getImportStateFromStorageByGroupId(groupId) {
    const [jobId, importState] =
      Object.entries(this.importStates)
        .reverse()
        .find(([, state]) => state.groups.some((g) => g.id === groupId)) ?? [];

    if (!jobId) {
      return null;
    }

    const group = importState.groups.find((g) => g.id === groupId);
    return { jobId, importState: { ...group, status: importState.status } };
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
