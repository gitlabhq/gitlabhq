<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['hasMissingProjectContext']),
    ...mapState(['groupInitialJson']),
    shouldShowSourceBranchFilter() {
      return (
        this.glFeatures.searchMrFilterSourceBranch &&
        (!this.hasMissingProjectContext || this.groupInitialJson?.id)
      );
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
    <source-branch-filter v-if="shouldShowSourceBranchFilter" class="gl-mb-5" />
  </filters-template>
</template>
