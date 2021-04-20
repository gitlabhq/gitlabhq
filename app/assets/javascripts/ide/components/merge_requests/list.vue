<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import TokenedInput from '../shared/tokened_input.vue';
import Item from './item.vue';

const SEARCH_TYPES = [
  { type: 'created', label: __('Created by me') },
  { type: 'assigned', label: __('Assigned to me') },
];

export default {
  components: {
    TokenedInput,
    Item,
    GlIcon,
    GlLoadingIcon,
  },
  data() {
    return {
      search: '',
      currentSearchType: null,
      hasSearchFocus: false,
    };
  },
  computed: {
    ...mapState('mergeRequests', ['mergeRequests', 'isLoading']),
    ...mapState(['currentMergeRequestId', 'currentProjectId']),
    hasMergeRequests() {
      return this.mergeRequests.length !== 0;
    },
    hasNoSearchResults() {
      return this.search !== '' && !this.hasMergeRequests;
    },
    showSearchTypes() {
      return this.hasSearchFocus && !this.search && !this.currentSearchType;
    },
    type() {
      return this.currentSearchType ? this.currentSearchType.type : '';
    },
    searchTokens() {
      return this.currentSearchType ? [this.currentSearchType] : [];
    },
  },
  watch: {
    search() {
      // When the search is updated, let's turn off this flag to hide the search types
      this.hasSearchFocus = false;
    },
  },
  mounted() {
    this.loadMergeRequests();
  },
  methods: {
    ...mapActions('mergeRequests', ['fetchMergeRequests']),
    loadMergeRequests() {
      this.fetchMergeRequests({ type: this.type, search: this.search });
    },
    searchMergeRequests: debounce(function debounceSearch() {
      this.loadMergeRequests();
    }, 250),
    onSearchFocus() {
      this.hasSearchFocus = true;
    },
    setSearchType(searchType) {
      this.currentSearchType = searchType;
      this.loadMergeRequests();
    },
  },
  searchTypes: SEARCH_TYPES,
};
</script>

<template>
  <div>
    <label
      class="dropdown-input gl-pt-3 gl-pb-5 gl-mb-0 gl-border-b-1 gl-border-b-solid gl-display-block"
      @click.stop
    >
      <tokened-input
        v-model="search"
        :tokens="searchTokens"
        :placeholder="__('Search merge requests')"
        @focus="onSearchFocus"
        @input="searchMergeRequests"
        @removeToken="setSearchType(null)"
      />
      <gl-icon :size="16" name="search" class="ml-3 input-icon" />
    </label>
    <div class="dropdown-content ide-merge-requests-dropdown-content d-flex">
      <gl-loading-icon
        v-if="isLoading"
        size="lg"
        class="mt-3 mb-3 align-self-center ml-auto mr-auto"
      />
      <template v-else>
        <ul class="mb-0 w-100">
          <template v-if="showSearchTypes">
            <li v-for="searchType in $options.searchTypes" :key="searchType.type">
              <button
                type="button"
                class="btn-link d-flex align-items-center"
                @click.stop="setSearchType(searchType)"
              >
                <span class="d-flex gl-mr-3 ide-search-list-current-icon">
                  <gl-icon :size="16" name="search" />
                </span>
                <span>{{ searchType.label }}</span>
              </button>
            </li>
          </template>
          <template v-else-if="hasMergeRequests">
            <li v-for="item in mergeRequests" :key="item.id">
              <item
                :item="item"
                :current-id="currentMergeRequestId"
                :current-project-id="currentProjectId"
              />
            </li>
          </template>
          <li v-else class="ide-search-list-empty d-flex align-items-center justify-content-center">
            {{ __('No merge requests found') }}
          </li>
        </ul>
      </template>
    </div>
  </div>
</template>
