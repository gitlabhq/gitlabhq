<script>
import _ from 'underscore';
import { GlLoadingIcon, GlSearchBoxByType, GlInfiniteScroll } from '@gitlab/ui';
import ProjectListItem from './project_list_item.vue';

const SEARCH_INPUT_TIMEOUT_MS = 500;

export default {
  name: 'ProjectSelector',
  components: {
    GlLoadingIcon,
    GlSearchBoxByType,
    GlInfiniteScroll,
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
    totalResults: {
      type: Number,
      required: false,
      default: 0,
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
    bottomReached() {
      this.$emit('bottomReached');
    },
    isSelected(project) {
      return Boolean(_.find(this.selectedProjects, { id: project.id }));
    },
    onInput: _.debounce(function debouncedOnInput() {
      this.$emit('searched', this.searchQuery);
    }, SEARCH_INPUT_TIMEOUT_MS),
  },
};
</script>
<template>
  <div>
    <gl-search-box-by-type
      v-model="searchQuery"
      :placeholder="__('Search your projects')"
      type="search"
      class="mb-3"
      autofocus
      @input="onInput"
    />
    <div class="d-flex flex-column">
      <gl-loading-icon v-if="showLoadingIndicator" :size="1" class="py-2 px-4" />
      <gl-infinite-scroll
        :max-list-height="402"
        :fetched-items="projectSearchResults.length"
        :total-items="totalResults"
        @bottomReached="bottomReached"
      >
        <div v-if="!showLoadingIndicator" slot="items" class="d-flex flex-column">
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
      </gl-infinite-scroll>
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
