import { defineStore } from 'pinia';

export const useMergeRequestVersions = defineStore('mergeRequestVersions', {
  state() {
    return {
      sourceVersions: [],
      targetVersions: [],
      commit: null,
    };
  },
  getters: {
    selectedSourceVersion() {
      return this.sourceVersions.find((v) => v.selected);
    },
    selectedTargetVersion() {
      return this.targetVersions.find((v) => v.selected);
    },
    commitId() {
      if (!this.commit) return null;
      return this.commit.id;
    },
    diffRefs() {
      if (this.commit) return this.commit.diff_refs;

      const source = this.selectedSourceVersion;
      const target = this.selectedTargetVersion;
      if (!source || !target) return null;
      if (target.head) {
        return {
          base_sha: target.start_sha,
          head_sha: target.head_sha,
          start_sha: target.start_sha,
        };
      }

      // Default "compare with master" view anchors start_sha at source.base_sha;
      // target.start_sha drifts with master and would not match stored positions.
      const startSha = target.version_index == null ? source.base_sha : target.start_sha;

      return {
        base_sha: source.base_sha,
        head_sha: source.head_sha,
        start_sha: startSha,
      };
    },
  },
  actions: {
    setVersions({ sourceVersions, targetVersions }) {
      this.sourceVersions = sourceVersions;
      this.targetVersions = targetVersions;
    },
    setCommit(commit) {
      this.commit = commit;
    },
  },
});
