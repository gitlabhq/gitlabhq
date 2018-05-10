<script>
import { removeParamQueryString } from '~/lib/utils/url_utility';
import CompareVersionsDropdown from './compare_versions_dropdown.vue';

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
      return this.mergeRequestDiffs.map(diff => ({
        ...diff,
        path: removeParamQueryString(diff.path, 'start_sha'),
      }));
    },
    baseVersions() {
      return this.mergeRequestDiffs.slice(1);
    },
    baseVersion() {
      return baseVersion;
    },
    mergeRequestDiff() {
      return this.mergeRequestDiffs[0];
    },
  },
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      Changes between
      <compare-versions-dropdown
        :other-versions="targetVersions"
        :latest-version="mergeRequestDiff"
        :show-commit-count="true"
        class="mr-version-dropdown"
      />
      and
      <compare-versions-dropdown
        :other-versions="baseVersions"
        :base-version="baseVersion"
        class="mr-version-compare-dropdown"
      />
    </div>
  </div>
</template>
