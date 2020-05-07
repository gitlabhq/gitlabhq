<script>
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import BranchesSearchList from './branches/search_list.vue';
import MergeRequestSearchList from './merge_requests/list.vue';

export default {
  components: {
    Tabs,
    Tab,
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
    <tabs v-if="showMergeRequests" stop-propagation>
      <tab active>
        <template #title>
          {{ __('Branches') }}
        </template>
        <branches-search-list />
      </tab>
      <tab>
        <template #title>
          {{ __('Merge Requests') }}
        </template>
        <merge-request-search-list />
      </tab>
    </tabs>
    <branches-search-list v-else />
  </div>
</template>
