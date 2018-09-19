<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import Item from './item.vue';

export default {
  components: {
    Item,
    Icon,
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapState('branches', ['branches', 'isLoading']),
    ...mapState(['currentBranchId', 'currentProjectId']),
    hasBranches() {
      return this.branches.length !== 0;
    },
    hasNoSearchResults() {
      return this.search !== '' && !this.hasBranches;
    },
  },
  watch: {
    isLoading: {
      handler: 'focusSearch',
    },
  },
  mounted() {
    this.loadBranches();
  },
  methods: {
    ...mapActions('branches', ['fetchBranches']),
    loadBranches() {
      this.fetchBranches({ search: this.search });
    },
    searchBranches: _.debounce(function debounceSearch() {
      this.loadBranches();
    }, 250),
    focusSearch() {
      if (!this.isLoading) {
        this.$nextTick(() => {
          this.$refs.searchInput.focus();
        });
      }
    },
    isActiveBranch(item) {
      return item.name === this.currentBranchId;
    },
  },
};
</script>

<template>
  <div>
    <div class="dropdown-input mt-3 pb-3 mb-0 border-bottom">
      <div class="position-relative">
        <input
          ref="searchInput"
          :placeholder="__('Search branches')"
          v-model="search"
          type="search"
          class="form-control dropdown-input-field"
          @input="searchBranches"
        />
        <icon
          :size="18"
          name="search"
          class="input-icon"
        />
      </div>
    </div>
    <div class="dropdown-content ide-merge-requests-dropdown-content d-flex">
      <gl-loading-icon
        v-if="isLoading"
        :size="2"
        class="mt-3 mb-3 align-self-center ml-auto mr-auto"
      />
      <ul
        v-else
        class="mb-3 w-100"
      >
        <template v-if="hasBranches">
          <li
            v-for="item in branches"
            :key="item.name"
          >
            <item
              :item="item"
              :project-id="currentProjectId"
              :is-active="isActiveBranch(item)"
            />
          </li>
        </template>
        <li
          v-else
          class="ide-search-list-empty d-flex align-items-center justify-content-center"
        >
          <template v-if="hasNoSearchResults">
            {{ __('No branches found') }}
          </template>
        </li>
      </ul>
    </div>
  </div>
</template>
