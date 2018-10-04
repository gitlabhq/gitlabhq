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
};
</script>

<template>
  <div
    class="ide-nav-form p-0"
  >
    <tabs
      stop-propagation
    >
      <tab
        active
      >
        <template slot="title">
          {{ __('Merge Requests') }}
        </template>
        <merge-request-search-list />
      </tab>
      <tab>
        <template slot="title">
          {{ __('Branches') }}
        </template>
        <branches-search-list />
      </tab>
    </tabs>
  </div>
</template>
