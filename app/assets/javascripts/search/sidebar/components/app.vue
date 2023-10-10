<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import SmallScreenDrawerNavigation from '~/search/sidebar/components/small_screen_drawer_navigation.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import {
  SCOPE_ISSUES,
  SCOPE_MERGE_REQUESTS,
  SCOPE_BLOB,
  SCOPE_PROJECTS,
  SCOPE_NOTES,
  SCOPE_COMMITS,
  SCOPE_MILESTONES,
  SEARCH_TYPE_ADVANCED,
} from '../constants';
import IssuesFilters from './issues_filters.vue';
import MergeRequestsFilters from './merge_requests_filters.vue';
import BlobsFilters from './blobs_filters.vue';
import ProjectsFilters from './projects_filters.vue';
import NotesFilters from './notes_filters.vue';
import CommitsFilters from './commits_filters.vue';
import MilestonesFilters from './milestones_filters.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    IssuesFilters,
    MergeRequestsFilters,
    BlobsFilters,
    ProjectsFilters,
    NotesFilters,
    ScopeLegacyNavigation,
    ScopeSidebarNavigation,
    SidebarPortal,
    DomElementListener,
    SmallScreenDrawerNavigation,
    CommitsFilters,
    MilestonesFilters,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    // useSidebarNavigation refers to whether the new left sidebar navigation is enabled
    ...mapState(['useSidebarNavigation', 'searchType']),
    ...mapGetters(['currentScope']),
    showIssuesFilters() {
      return this.currentScope === SCOPE_ISSUES;
    },
    showMergeRequestFilters() {
      return this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilters() {
      return this.currentScope === SCOPE_BLOB && this.searchType === SEARCH_TYPE_ADVANCED;
    },
    showProjectsFilters() {
      return this.currentScope === SCOPE_PROJECTS;
    },
    showNotesFilters() {
      // for now, the feature flag is placed here. Since we have only one filter in notes scope
      return this.currentScope === SCOPE_NOTES && this.glFeatures.searchNotesHideArchivedProjects;
    },
    showCommitsFilters() {
      // for now, the feature flag is placed here. Since we have only one filter in commits scope
      return (
        this.currentScope === SCOPE_COMMITS && this.glFeatures.searchCommitsHideArchivedProjects
      );
    },
    showMilestonesFilters() {
      // for now, the feature flag is placed here. Since we have only one filter in milestones scope
      return (
        this.currentScope === SCOPE_MILESTONES &&
        this.glFeatures.searchMilestonesHideArchivedProjects
      );
    },
    showScopeNavigation() {
      // showScopeNavigation refers to whether the scope navigation should be shown
      // while the legacy navigation is being used and there are no search results
      // the scope navigation has to be hidden
      return Boolean(this.currentScope);
    },
  },
  methods: {
    toggleFiltersFromSidebar() {
      toggleSuperSidebarCollapsed();
    },
  },
};
</script>

<template>
  <section v-if="useSidebarNavigation">
    <dom-element-listener selector="#js-open-mobile-filters" @click="toggleFiltersFromSidebar" />
    <sidebar-portal>
      <scope-sidebar-navigation />
      <issues-filters v-if="showIssuesFilters" />
      <merge-requests-filters v-if="showMergeRequestFilters" />
      <blobs-filters v-if="showBlobFilters" />
      <projects-filters v-if="showProjectsFilters" />
      <notes-filters v-if="showNotesFilters" />
      <commits-filters v-if="showCommitsFilters" />
      <milestones-filters v-if="showMilestonesFilters" />
    </sidebar-portal>
  </section>

  <section
    v-else-if="showScopeNavigation"
    class="gl-display-flex gl-flex-direction-column gl-lg-mr-0 gl-md-mr-5 gl-lg-mb-6 gl-lg-mt-5"
  >
    <div class="search-sidebar gl-display-none gl-lg-display-block">
      <scope-legacy-navigation />
      <issues-filters v-if="showIssuesFilters" />
      <merge-requests-filters v-if="showMergeRequestFilters" />
      <blobs-filters v-if="showBlobFilters" />
      <projects-filters v-if="showProjectsFilters" />
      <notes-filters v-if="showNotesFilters" />
      <commits-filters v-if="showCommitsFilters" />
      <milestones-filters v-if="showMilestonesFilters" />
    </div>
    <small-screen-drawer-navigation class="gl-lg-display-none">
      <scope-legacy-navigation />
      <issues-filters v-if="showIssuesFilters" />
      <merge-requests-filters v-if="showMergeRequestFilters" />
      <blobs-filters v-if="showBlobFilters" />
      <projects-filters v-if="showProjectsFilters" />
      <notes-filters v-if="showNotesFilters" />
      <commits-filters v-if="showCommitsFilters" />
      <milestones-filters v-if="showMilestonesFilters" />
    </small-screen-drawer-navigation>
  </section>
</template>
