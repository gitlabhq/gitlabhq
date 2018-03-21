<script>
import bs from '../../breakpoints';
import eventHub from '../event_hub';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

import projectsListFrequent from './projects_list_frequent.vue';
import projectsListSearch from './projects_list_search.vue';

import search from './search.vue';

export default {
  components: {
    search,
    loadingIcon,
    projectsListFrequent,
    projectsListSearch,
  },
  props: {
    currentProject: {
      type: Object,
      required: true,
    },
    store: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoadingProjects: false,
      isFrequentsListVisible: false,
      isSearchListVisible: false,
      isLocalStorageFailed: false,
      isSearchFailed: false,
      searchQuery: '',
    };
  },
  computed: {
    frequentProjects() {
      return this.store.getFrequentProjects();
    },
    searchProjects() {
      return this.store.getSearchedProjects();
    },
  },
  created() {
    if (this.currentProject.id) {
      this.logCurrentProjectAccess();
    }

    eventHub.$on('dropdownOpen', this.fetchFrequentProjects);
    eventHub.$on('searchProjects', this.fetchSearchedProjects);
    eventHub.$on('searchCleared', this.handleSearchClear);
    eventHub.$on('searchFailed', this.handleSearchFailure);
  },
  beforeDestroy() {
    eventHub.$off('dropdownOpen', this.fetchFrequentProjects);
    eventHub.$off('searchProjects', this.fetchSearchedProjects);
    eventHub.$off('searchCleared', this.handleSearchClear);
    eventHub.$off('searchFailed', this.handleSearchFailure);
  },
  methods: {
    toggleFrequentProjectsList(state) {
      this.isLoadingProjects = !state;
      this.isSearchListVisible = !state;
      this.isFrequentsListVisible = state;
    },
    toggleSearchProjectsList(state) {
      this.isLoadingProjects = !state;
      this.isFrequentsListVisible = !state;
      this.isSearchListVisible = state;
    },
    toggleLoader(state) {
      this.isFrequentsListVisible = !state;
      this.isSearchListVisible = !state;
      this.isLoadingProjects = state;
    },
    fetchFrequentProjects() {
      const screenSize = bs.getBreakpointSize();
      if (this.searchQuery && (screenSize !== 'sm' && screenSize !== 'xs')) {
        this.toggleSearchProjectsList(true);
      } else {
        this.toggleLoader(true);
        this.isLocalStorageFailed = false;
        const projects = this.service.getFrequentProjects();
        if (projects) {
          this.toggleFrequentProjectsList(true);
          this.store.setFrequentProjects(projects);
        } else {
          this.isLocalStorageFailed = true;
          this.toggleFrequentProjectsList(true);
          this.store.setFrequentProjects([]);
        }
      }
    },
    fetchSearchedProjects(searchQuery) {
      this.searchQuery = searchQuery;
      this.toggleLoader(true);
      this.service.getSearchedProjects(this.searchQuery)
        .then(res => res.json())
        .then((results) => {
          this.toggleSearchProjectsList(true);
          this.store.setSearchedProjects(results);
        })
        .catch(() => {
          this.isSearchFailed = true;
          this.toggleSearchProjectsList(true);
        });
    },
    logCurrentProjectAccess() {
      this.service.logProjectAccess(this.currentProject);
    },
    handleSearchClear() {
      this.searchQuery = '';
      this.toggleFrequentProjectsList(true);
      this.store.clearSearchedProjects();
    },
    handleSearchFailure() {
      this.isSearchFailed = true;
      this.toggleSearchProjectsList(true);
    },
  },
};
</script>

<template>
  <div>
    <search/>
    <loading-icon
      class="loading-animation prepend-top-20"
      size="2"
      v-if="isLoadingProjects"
      :label="s__('ProjectsDropdown|Loading projects')"
    />
    <div
      class="section-header"
      v-if="isFrequentsListVisible"
    >
      {{ s__('ProjectsDropdown|Frequently visited') }}
    </div>
    <projects-list-frequent
      v-if="isFrequentsListVisible"
      :local-storage-failed="isLocalStorageFailed"
      :projects="frequentProjects"
    />
    <projects-list-search
      v-if="isSearchListVisible"
      :search-failed="isSearchFailed"
      :matcher="searchQuery"
      :projects="searchProjects"
    />
  </div>
</template>
