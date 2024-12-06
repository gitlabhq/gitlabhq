<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
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
  SEARCH_TYPE_ZOEKT,
} from '../constants';
import IssuesFilters from './issues_filters.vue';
import MergeRequestsFilters from './merge_requests_filters.vue';
import BlobsFilters from './blobs_filters.vue';
import ProjectsFilters from './projects_filters.vue';
import NotesFilters from './notes_filters.vue';
import CommitsFilters from './commits_filters.vue';
import MilestonesFilters from './milestones_filters.vue';
import WikiBlobsFilters from './wiki_blobs_filters.vue';
import AllScopesStartFilters from './all_scopes_start_filters.vue';

export default {
  i18n: {
    headerText: __('Search results'),
  },
  name: 'GlobalSearchSidebar',
  components: {
    IssuesFilters,
    MergeRequestsFilters,
    BlobsFilters,
    ProjectsFilters,
    NotesFilters,
    WikiBlobsFilters,
    ScopeSidebarNavigation,
    SidebarPortal,
    DomElementListener,
    CommitsFilters,
    MilestonesFilters,
    AllScopesStartFilters,
  },
  computed: {
    ...mapState(['searchType']),
    ...mapGetters(['currentScope']),
    isBlobScope() {
      return this.currentScope === SCOPE_BLOB;
    },
    isAdvancedSearch() {
      return this.searchType === SEARCH_TYPE_ADVANCED;
    },
    isZoektSearch() {
      return this.searchType === SEARCH_TYPE_ZOEKT;
    },
    showIssuesFilters() {
      return this.currentScope === SCOPE_ISSUES;
    },
    showMergeRequestFilters() {
      return this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilters() {
      return this.isBlobScope && (this.isAdvancedSearch || this.isZoektSearch);
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
      return this.currentScope === SCOPE_WIKI_BLOBS;
    },
  },
  beforeCreate() {
    if (!this.$store) {
      Sentry.captureException('GlobalSearchSidebar was not provided a Vuex store');
    }
  },
  methods: {
    toggleFiltersFromSidebar() {
      toggleSuperSidebarCollapsed();
    },
  },
};
</script>

<template>
  <section>
    <dom-element-listener selector="#js-open-mobile-filters" @click="toggleFiltersFromSidebar" />
    <sidebar-portal>
      <div
        class="super-sidebar-context-header gl-m-0 gl-px-4 gl-py-3 gl-font-bold gl-leading-reset"
      >
        {{ $options.i18n.headerText }}
      </div>
      <all-scopes-start-filters />
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
</template>
