<script>
import CompareVersionsDropdown from './compare_versions_dropdown.vue';

export default {
  components: {
    CompareVersionsDropdown,
  },
  props: {
    mergeRequestDiffs: {
      type: Array,
      required: true,
    },
    mergeRequestDiff: {
      type: Object,
      required: true,
    },
    startVersion: {
      type: Object,
      required: false,
      default: null,
    },
    targetBranch: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    comparableDiffs() {
      return this.mergeRequestDiffs.slice(1);
    },
  },
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      Changes between
      <compare-versions-dropdown
        :other-versions="mergeRequestDiffs"
        :merge-request-version="mergeRequestDiff"
        :show-commit-count="true"
        class="mr-version-dropdown"
      />
      and
      <compare-versions-dropdown
        :other-versions="comparableDiffs"
        :start-version="startVersion"
        :target-branch="targetBranch"
        class="mr-version-compare-dropdown"
      />
    </div>
  </div>
</template>
