<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import Item from './item.vue';
import TokenedInput from '../shared/tokened_input.vue';

const SEARCH_TYPES = [
  { type: 'created', label: __('Created by me') },
  { type: 'assigned', label: __('Assigned to me') },
];

export default {
  components: {
    TokenedInput,
    Item,
    Icon,
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
    searchMergeRequests: _.debounce(function debounceSearch() {
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
    <label class="dropdown-input pt-3 pb-3 mb-0 border-bottom block" @click.stop>
      <tokened-input
        v-model="search"
        :tokens="searchTokens"
        :placeholder="__('Search merge requests')"
        @focus="onSearchFocus"
        @input="searchMergeRequests"
        @removeToken="setSearchType(null)"
      />
      <icon :size="18" name="search" class="ml-3 input-icon" />
    </label>
    <div class="dropdown-content ide-merge-requests-dropdown-content d-flex">
      <gl-loading-icon
        v-if="isLoading"
        :size="2"
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
                <span class="d-flex append-right-default ide-search-list-current-icon">
                  <icon :size="18" name="search" />
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
