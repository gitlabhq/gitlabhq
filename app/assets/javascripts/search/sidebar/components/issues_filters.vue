<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import { SEARCH_TYPE_ADVANCED, SCOPE_WORK_ITEMS } from '~/search/sidebar/constants';
import ConfidentialityFilter from './confidentiality_filter/index.vue';
import LabelFilter from './label_filter/index.vue';
import StatusFilter from './status_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import TypeFilter from './type_filter/index.vue';

import FiltersTemplate from './filters_template.vue';

export default {
  name: 'IssuesFilters',
  components: {
    TypeFilter,
    StatusFilter,
    ConfidentialityFilter,
    LabelFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  computed: {
    ...mapGetters(['hasMissingProjectContext', 'currentScope', 'workItemTypes']),
    ...mapState(['searchType']),
    showLabelFilter() {
      return this.searchType === SEARCH_TYPE_ADVANCED;
    },
    showTypeFilter() {
      return this.currentScope === SCOPE_WORK_ITEMS && this.workItemTypes.length > 0;
    },
  },
};
</script>

<template>
  <filters-template>
    <type-filter v-if="showTypeFilter" class="gl-mb-5" />
    <status-filter class="gl-mb-5" />
    <confidentiality-filter class="gl-mb-5" />
    <label-filter v-if="showLabelFilter" class="gl-mb-5" />
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
  </filters-template>
</template>
