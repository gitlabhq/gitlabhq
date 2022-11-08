<script>
import { mapState } from 'vuex';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';
import { SCOPE_ISSUES, SCOPE_MERGE_REQUESTS } from '../constants';
import ResultsFilters from './results_filters.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    ResultsFilters,
    ScopeNavigation,
  },
  computed: {
    ...mapState(['urlQuery']),
    showFilters() {
      return this.urlQuery.scope === SCOPE_ISSUES || this.urlQuery.scope === SCOPE_MERGE_REQUESTS;
    },
  },
};
</script>

<template>
  <section class="search-sidebar gl-display-flex gl-flex-direction-column gl-mr-4 gl-mb-6 gl-mt-5">
    <scope-navigation />
    <results-filters v-if="showFilters" />
  </section>
</template>
