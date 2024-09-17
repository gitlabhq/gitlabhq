<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import Item from './item.vue';

export default {
  components: {
    Item,
    GlIcon,
    GlLoadingIcon,
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
    searchBranches: debounce(function debounceSearch() {
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
    <label
      class="dropdown-input gl-mb-0 gl-block gl-border-b-1 gl-pb-5 gl-pt-3 gl-border-b-solid"
      @click.stop
    >
      <input
        ref="searchInput"
        v-model="search"
        :placeholder="__('Search branches')"
        type="search"
        class="form-control dropdown-input-field"
        @input="searchBranches"
      />
      <gl-icon name="search" class="input-icon gl-ml-5 gl-mt-1" />
    </label>
    <div class="dropdown-content ide-merge-requests-dropdown-content !gl-flex">
      <gl-loading-icon
        v-if="isLoading"
        size="lg"
        class="mt-3 mb-3 align-self-center ml-auto mr-auto"
      />
      <ul v-else class="mb-0 gl-w-full">
        <template v-if="hasBranches">
          <li v-for="item in branches" :key="item.name">
            <item :item="item" :project-id="currentProjectId" :is-active="isActiveBranch(item)" />
          </li>
        </template>
        <li v-else class="ide-search-list-empty !gl-flex gl-items-center gl-justify-center">
          <template v-if="hasNoSearchResults">
            {{ __('No branches found') }}
          </template>
        </li>
      </ul>
    </div>
  </div>
</template>
