<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import SmallScreenDrawerNavigation from '~/search/sidebar/components/small_screen_drawer_navigation.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import {
  SCOPE_ISSUES,
  SCOPE_MERGE_REQUESTS,
  SCOPE_BLOB,
  SCOPE_PROJECTS,
  SCOPE_NOTES,
  SCOPE_COMMITS,
  SCOPE_MILESTONES,
  SCOPE_WIKI_BLOBS,
  SEARCH_TYPE_ADVANCED,
} from '../constants';
import IssuesFilters from './issues_filters.vue';
import MergeRequestsFilters from './merge_requests_filters.vue';
import BlobsFilters from './blobs_filters.vue';
import ProjectsFilters from './projects_filters.vue';
import NotesFilters from './notes_filters.vue';
import CommitsFilters from './commits_filters.vue';
import MilestonesFilters from './milestones_filters.vue';
import WikiBlobsFilters from './wiki_blobs_filters.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    IssuesFilters,
    MergeRequestsFilters,
    BlobsFilters,
    ProjectsFilters,
    NotesFilters,
    WikiBlobsFilters,
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
      return this.currentScope === SCOPE_NOTES;
    },
    showCommitsFilters() {
      return this.currentScope === SCOPE_COMMITS;
    },
    showMilestonesFilters() {
      return this.currentScope === SCOPE_MILESTONES;
    },
    showWikiBlobsFilters() {
      return (
        this.currentScope === SCOPE_WIKI_BLOBS &&
        this.glFeatures?.searchProjectWikisHideArchivedProjects
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
      <wiki-blobs-filters v-if="showWikiBlobsFilters" />
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
      <wiki-blobs-filters v-if="showWikiBlobsFilters" />
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
      <wiki-blobs-filters v-if="showWikiBlobsFilters" />
    </small-screen-drawer-navigation>
  </section>
</template>
