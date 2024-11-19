<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SEARCH_TYPE_ADVANCED } from '~/search/sidebar/constants';
import StatusFilter from './status_filter/index.vue';
import FiltersTemplate from './filters_template.vue';
import LabelFilter from './label_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import SourceBranchFilter from './source_branch_filter/index.vue';

export default {
  name: 'MergeRequestsFilters',
  components: {
    StatusFilter,
    FiltersTemplate,
    LabelFilter,
    ArchivedFilter,
    SourceBranchFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['hasMissingProjectContext']),
    ...mapState(['groupInitialJson', 'searchType']),
    shouldShowSourceBranchFilter() {
      return (
        this.glFeatures.searchMrFilterSourceBranch &&
        (!this.hasMissingProjectContext || this.groupInitialJson?.id)
      );
    },
    shouldShowLabelFilter() {
      return this.searchType === SEARCH_TYPE_ADVANCED && this.glFeatures.searchMrFilterLabelIds;
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
    <label-filter v-if="shouldShowLabelFilter" class="gl-mb-5" />
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
    <source-branch-filter v-if="shouldShowSourceBranchFilter" class="gl-mb-5" />
  </filters-template>
</template>
