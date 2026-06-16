import { defineStore } from 'pinia';

export const useMergeRequestVersions = defineStore('mergeRequestVersions', {
  state() {
    return {
      sourceVersions: [],
      targetVersions: [],
      contextCommits: null,
      commit: null,
    };
  },
  getters: {
    isViewingContextCommits() {
      return Boolean(this.contextCommits?.selected);
    },
    selectedSourceVersion() {
      if (this.isViewingContextCommits) return this.contextCommits;
      return this.sourceVersions.find((v) => v.selected);
    },
    selectedTargetVersion() {
      return this.targetVersions.find((v) => v.selected);
    },
    commitId() {
      if (!this.commit) return null;
      return this.commit.id;
    },
    isLatestVersion() {
      if (this.commit) return false;
      return Boolean(this.selectedSourceVersion?.latest);
    },
    sourceHeadSha() {
      if (this.commit) return this.commit.id;
      return this.selectedSourceVersion?.head_sha ?? null;
    },
    diffRefs() {
      if (this.commit) return this.commit.diff_refs;
      if (this.isViewingContextCommits) return this.contextCommits.diff_refs;

      const source = this.selectedSourceVersion;
      const target = this.selectedTargetVersion;
      if (!source || !target) return null;
      // Only use merge-head refs when the source is the latest version. The merge-head ref is
      // dynamic (re-anchored to master on every push), so it cannot identify a stable draft
      // position against an older source version — published notes are repositioned by the
      // backend, drafts are not. When source is not latest, fall through to source-anchored refs.
      if (target.is_merge_head && source.latest) {
        return {
          base_sha: target.start_sha,
          head_sha: target.head_sha,
          start_sha: target.start_sha,
        };
      }

      // Mirror the backend's diff_refs:
      // - Compare with target branch (version_index null): base_sha anchored at source.base_sha;
      //   target.start_sha drifts with master and would not match stored positions.
      // - Version-to-version compare (version_index present): backend uses a straight diff
      //   (Compare#diff_refs with @straight=true), which collapses base_sha onto start_sha.
      const baseAndStart = target.version_index == null ? source.base_sha : target.start_sha;

      return {
        base_sha: baseAndStart,
        head_sha: source.head_sha,
        start_sha: baseAndStart,
      };
    },
  },
  actions: {
    setVersions({ sourceVersions, targetVersions, contextCommits = null }) {
      this.sourceVersions = sourceVersions;
      this.targetVersions = targetVersions;
      this.contextCommits = contextCommits;
    },
    setCommit(commit) {
      this.commit = commit;
    },
  },
});
