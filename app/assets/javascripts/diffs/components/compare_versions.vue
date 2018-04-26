<script>
import CompareVersionsDropdown from './compare_versions_dropdown.vue';

const mergeRequestDiff = {
  latest: true,
  path: 'www.blah.com', // link_to merge_request_version_path(@project, @merge_request, merge_request_diff, @start_sha)
  versionIndex: 4, // version #{version_index(merge_request_diff)}
  shortCommitSha: 'abcd1234', // short_sha(merge_request_diff.head_commit_sha)
  commitsCount: 3, // merge_request_diff.commits_count
  createdAt: '2017-03-14T21:27:21Z', // .created_at
};

const baseVersion = {
  latest: true,
  branchName: 'master',
  path: 'www.blah.com', // link_to merge_request_version_path(@project, @merge_request, merge_request_diff, @start_sha)
  versionIndex: 4, // version #{version_index(merge_request_diff)}
  shortCommitSha: 'def1342a', // short_sha(merge_request_diff.head_commit_sha)
  commitsCount: 3, // merge_request_diff.commits_count
  createdAt: '2017-03-14T21:27:21Z', // .created_at
};

export default {
  components: {
    CompareVersionsDropdown,
  },
  props: {
    mergeRequestDiffs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    targetVersions() {
      return this.mergeRequestDiffs;
    },
    baseVersions() {
      return this.mergeRequestDiffs;
    },
    baseVersion() {
      return baseVersion;
    },
    mergeRequestDiff() {
      return mergeRequestDiff;
    }
  }
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      Changes between
      <compare-versions-dropdown
        :other-versions="targetVersions"
        :latest-version="mergeRequestDiff"
      />
      and
      <compare-versions-dropdown
        :other-versions="targetVersions"
        :base-version="baseVersion"
      />
    </div>
  </div>
</template>
