<script>
import { STATUS_OPEN } from '~/issues/constants';
import { __ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';

export default {
  i18n: {
    searchPlaceholder: __('Search or filter results...'),
  },
  issuableListTabs,
  components: {
    IssuableList,
  },
  data() {
    return {
      issues: [],
      searchTokens: [],
      sortOptions: [],
      state: STATUS_OPEN,
    };
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :issuables="issues"
    namespace="work-items"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchPlaceholder"
    :search-tokens="searchTokens"
    :sort-options="sortOptions"
    :tabs="$options.issuableListTabs"
  />
</template>
