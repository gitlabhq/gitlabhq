<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { HR_DEFAULT_CLASSES } from '../constants';
import { statusFilterData } from './status_filter/data';
import StatusFilter from './status_filter/index.vue';
import FiltersTemplate from './filters_template.vue';
import { archivedFilterData } from './archived_filter/data';
import ArchivedFilter from './archived_filter/index.vue';

export default {
  name: 'MergeRequestsFilters',
  components: {
    StatusFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentScope']),
    ...mapState(['useSidebarNavigation', 'searchType']),
    showArchivedFilter() {
      return (
        archivedFilterData.scopes.includes(this.currentScope) &&
        this.glFeatures.searchMergeRequestsHideArchivedProjects
      );
    },
    showStatusFilter() {
      return Object.values(statusFilterData.scopes).includes(this.currentScope);
    },
    showDivider() {
      return !this.useSidebarNavigation;
    },
    hrClasses() {
      return [...HR_DEFAULT_CLASSES, 'gl-display-none', 'gl-md-display-block'];
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter v-if="showStatusFilter" class="gl-mb-5" />
    <hr v-if="showArchivedFilter && showDivider" :class="hrClasses" />
    <archived-filter v-if="showArchivedFilter" class="gl-mb-5" />
  </filters-template>
</template>
