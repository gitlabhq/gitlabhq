<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import StatusFilter from './status_filter/index.vue';
import FiltersTemplate from './filters_template.vue';
import ArchivedFilter from './archived_filter/index.vue';
import SourceBranchFilter from './source_branch_filter/index.vue';

export default {
  name: 'MergeRequestsFilters',
  components: {
    StatusFilter,
    FiltersTemplate,
    ArchivedFilter,
    SourceBranchFilter,
  },
  computed: {
    ...mapGetters(['hasProjectContext']),
    ...mapState(['groupInitialJson']),
    shouldShowSourceBranchFilter() {
      // this will be changed https://gitlab.com/gitlab-org/gitlab/-/issues/480740
      return !this.hasProjectContext || this.groupInitialJson?.id;
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
    <archived-filter v-if="hasProjectContext" class="gl-mb-5" />
    <source-branch-filter v-if="shouldShowSourceBranchFilter" class="gl-mb-5" />
  </filters-template>
</template>
