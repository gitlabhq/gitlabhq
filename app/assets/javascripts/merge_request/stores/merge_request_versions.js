import { defineStore } from 'pinia';

export const useMergeRequestVersions = defineStore('mergeRequestVersions', {
  state() {
    return {
      sourceVersions: [],
      targetVersions: [],
    };
  },
  getters: {
    selectedSourceVersion() {
      return this.sourceVersions.find((v) => v.selected);
    },
    selectedTargetVersion() {
      return this.targetVersions.find((v) => v.selected);
    },
    diffRefs() {
      const source = this.selectedSourceVersion;
      const target = this.selectedTargetVersion;
      if (!source || !target) return null;
      return {
        base_sha: source.base_sha,
        head_sha: source.head_sha,
        start_sha: target.start_sha,
      };
    },
  },
  actions: {
    setVersions({ sourceVersions, targetVersions }) {
      this.sourceVersions = sourceVersions;
      this.targetVersions = targetVersions;
    },
  },
});
