<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import BranchesSearchList from './branches/search_list.vue';
import MergeRequestSearchList from './merge_requests/list.vue';

export default {
  components: {
    GlTab,
    GlTabs,
    BranchesSearchList,
    MergeRequestSearchList,
  },
  props: {
    showMergeRequests: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="ide-nav-form p-0">
    <gl-tabs v-if="showMergeRequests">
      <gl-tab :title="__('Branches')">
        <branches-search-list />
      </gl-tab>
      <gl-tab :title="__('Merge requests')">
        <merge-request-search-list />
      </gl-tab>
    </gl-tabs>
    <branches-search-list v-else />
  </div>
</template>
