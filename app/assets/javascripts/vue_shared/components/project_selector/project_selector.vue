<script>
import { GlLoadingIcon, GlSearchBoxByType, GlInfiniteScroll } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __, n__, sprintf } from '~/locale';
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
    maxListHeight: {
      type: Number,
      required: false,
      default: 402,
    },
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
      required: true,
    },
    showMinimumSearchQueryMessage: {
      type: Boolean,
      required: true,
    },
    showLoadingIndicator: {
      type: Boolean,
      required: true,
    },
    showSearchErrorMessage: {
      type: Boolean,
      required: true,
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
      hasSearched: false,
    };
  },
  computed: {
    legendText() {
      if (!this.hasSearched) {
        return '';
      }
      const count = this.projectSearchResults.length;
      const total = this.totalResults;

      if (total > 0) {
        return sprintf(__('Showing %{count} of %{total} projects'), { count, total });
      }

      return sprintf(n__('Showing %{count} project', 'Showing %{count} projects', count), {
        count,
      });
    },
  },
  methods: {
    projectClicked(project) {
      this.$emit('projectClicked', project);
    },
    bottomReached() {
      this.$emit('bottomReached');
    },
    isSelected(project) {
      return this.selectedProjects.some(({ id }) => project.id === id);
    },
    onInput: debounce(function debouncedOnInput() {
      if (!this.hasSearched) {
        this.hasSearched = true;
      }
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
      data-testid="project-search-field"
      @input="onInput"
    />
    <div class="flex-column gl-flex">
      <gl-loading-icon v-if="showLoadingIndicator" size="sm" class="py-2 px-4" />
      <gl-infinite-scroll
        :max-list-height="maxListHeight"
        :fetched-items="projectSearchResults.length"
        :total-items="totalResults"
        @bottomReached="bottomReached"
      >
        <template v-if="!showLoadingIndicator" #items>
          <div class="gl-flex gl-flex-col gl-p-3">
            <project-list-item
              v-for="project in projectSearchResults"
              :key="project.id"
              :selected="isSelected(project)"
              :project="project"
              :matcher="searchQuery"
              class="js-project-list-item"
              data-testid="project-list-item"
              @click="projectClicked(project)"
            />
          </div>
        </template>

        <template #default>
          <span data-testid="legend-text">{{ legendText }}</span>
        </template>
      </gl-infinite-scroll>
      <div v-if="showNoResultsMessage" class="js-no-results-message gl-ml-3 gl-text-subtle">
        {{ __('Sorry, no projects matched your search') }}
      </div>
      <div
        v-if="showMinimumSearchQueryMessage"
        class="js-minimum-search-query-message gl-ml-3 gl-text-subtle"
      >
        {{ __('Enter at least three characters to search') }}
      </div>
      <div
        v-if="showSearchErrorMessage"
        class="js-search-error-message gl-ml-3 gl-font-bold gl-text-red-500"
      >
        {{ __('Something went wrong, unable to search projects') }}
      </div>
    </div>
  </div>
</template>
