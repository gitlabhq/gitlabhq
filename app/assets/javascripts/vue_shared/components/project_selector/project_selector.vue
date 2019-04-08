<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import ProjectListItem from './project_list_item.vue';

const SEARCH_INPUT_TIMEOUT_MS = 500;

export default {
  name: 'ProjectSelector',
  components: {
    GlLoadingIcon,
    ProjectListItem,
  },
  props: {
    projectSearchResults: {
      type: Array,
      required: true,
    },
    selectedProjects: {
      type: Array,
      required: true,
    },
    showNoResultsMessage: {
      type: Boolean,
      required: false,
      default: false,
    },
    showMinimumSearchQueryMessage: {
      type: Boolean,
      required: false,
      default: false,
    },
    showLoadingIndicator: {
      type: Boolean,
      required: false,
      default: false,
    },
    showSearchErrorMessage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  methods: {
    projectClicked(project) {
      this.$emit('projectClicked', project);
    },
    isSelected(project) {
      return Boolean(_.findWhere(this.selectedProjects, { id: project.id }));
    },
    focusSearchInput() {
      this.$refs.searchInput.focus();
    },
    onInput: _.debounce(function debouncedOnInput() {
      this.$emit('searched', this.searchQuery);
    }, SEARCH_INPUT_TIMEOUT_MS),
  },
};
</script>
<template>
  <div>
    <input
      ref="searchInput"
      v-model="searchQuery"
      :placeholder="__('Search your projects')"
      type="search"
      class="form-control mb-3 js-project-selector-input"
      autofocus
      @input="onInput"
    />
    <div class="d-flex flex-column">
      <gl-loading-icon v-if="showLoadingIndicator" :size="2" class="py-2 px-4" />
      <div v-if="!showLoadingIndicator" class="d-flex flex-column">
        <project-list-item
          v-for="project in projectSearchResults"
          :key="project.id"
          :selected="isSelected(project)"
          :project="project"
          :matcher="searchQuery"
          class="js-project-list-item"
          @click="projectClicked(project)"
        />
      </div>
      <div v-if="showNoResultsMessage" class="text-muted ml-2 js-no-results-message">
        {{ __('Sorry, no projects matched your search') }}
      </div>
      <div
        v-if="showMinimumSearchQueryMessage"
        class="text-muted ml-2 js-minimum-search-query-message"
      >
        {{ __('Enter at least three characters to search') }}
      </div>
      <div v-if="showSearchErrorMessage" class="text-danger ml-2 js-search-error-message">
        {{ __('Something went wrong, unable to search projects') }}
      </div>
    </div>
  </div>
</template>
