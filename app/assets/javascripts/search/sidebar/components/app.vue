<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SCOPE_ISSUES, SCOPE_MERGE_REQUESTS, SCOPE_BLOB, SCOPE_PROJECTS } from '../constants';
import IssuesFilters from './issues_filters.vue';
import MergeRequestsFilters from './merge_requests_filters.vue';
import BlobsFilters from './blobs_filters.vue';
import ProjectsFilters from './projects_filters.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    IssuesFilters,
    ScopeLegacyNavigation,
    ScopeSidebarNavigation,
    SidebarPortal,
    MergeRequestsFilters,
    BlobsFilters,
    ProjectsFilters,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    // useSidebarNavigation refers to whether the new left sidebar navigation is enabled
    ...mapState(['useSidebarNavigation']),
    ...mapGetters(['currentScope']),
    showIssuesFilters() {
      return this.currentScope === SCOPE_ISSUES;
    },
    showMergeRequestFilters() {
      return this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilters() {
      return this.currentScope === SCOPE_BLOB;
    },
    showProjectsFilters() {
      // for now the feature flag is here. Since we have only one filter in projects scope
      return this.currentScope === SCOPE_PROJECTS;
    },
    showScopeNavigation() {
      // showScopeNavigation refers to whether the scope navigation should be shown
      // while the legacy navigation is being used and there are no search results
      // the scope navigation has to be hidden
      return Boolean(this.currentScope);
    },
  },
};
</script>

<template>
  <section v-if="useSidebarNavigation">
    <sidebar-portal>
      <scope-sidebar-navigation />
      <issues-filters v-if="showIssuesFilters" />
      <merge-requests-filters v-if="showMergeRequestFilters" />
      <blobs-filters v-if="showBlobFilters" />
      <projects-filters v-if="showProjectsFilters" />
    </sidebar-portal>
  </section>
  <section
    v-else-if="showScopeNavigation"
    class="search-sidebar gl-display-flex gl-flex-direction-column gl-md-mr-5 gl-mb-6 gl-mt-5"
  >
    <scope-legacy-navigation />
    <issues-filters v-if="showIssuesFilters" />
    <merge-requests-filters v-if="showMergeRequestFilters" />
    <blobs-filters v-if="showBlobFilters" />
    <projects-filters v-if="showProjectsFilters" />
  </section>
</template>
