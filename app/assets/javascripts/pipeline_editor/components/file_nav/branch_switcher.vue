<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlInfiniteScroll,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import {
  BRANCH_PAGINATION_LIMIT,
  BRANCH_SEARCH_DEBOUNCE,
  DEFAULT_FAILURE,
} from '~/pipeline_editor/constants';
import getAvailableBranches from '~/pipeline_editor/graphql/queries/available_branches.graphql';
import getCurrentBranch from '~/pipeline_editor/graphql/queries/client/current_branch.graphql';

export default {
  i18n: {
    dropdownHeader: s__('Switch Branch'),
    title: s__('Branches'),
    fetchError: s__('Unable to fetch branch list for this project.'),
  },
  inputDebounce: BRANCH_SEARCH_DEBOUNCE,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlInfiniteScroll,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  inject: ['projectFullPath', 'totalBranches'],
  props: {
    paginationLimit: {
      type: Number,
      required: false,
      default: BRANCH_PAGINATION_LIMIT,
    },
  },
  data() {
    return {
      branches: [],
      page: {
        limit: this.paginationLimit,
        offset: 0,
        searchTerm: '',
      },
    };
  },
  apollo: {
    availableBranches: {
      query: getAvailableBranches,
      variables() {
        return {
          limit: this.page.limit,
          offset: this.page.offset,
          projectFullPath: this.projectFullPath,
          searchPattern: this.searchPattern,
        };
      },
      update(data) {
        return data.project?.repository?.branchNames || [];
      },
      result({ data }) {
        const newBranches = data.project?.repository?.branchNames || [];

        // check that we're not re-concatenating existing fetch results
        if (!this.branches.includes(newBranches[0])) {
          this.branches = this.branches.concat(newBranches);
        }
      },
      error() {
        this.$emit('showError', {
          type: DEFAULT_FAILURE,
          reasons: [this.$options.i18n.fetchError],
        });
      },
    },
    currentBranch: {
      query: getCurrentBranch,
    },
  },
  computed: {
    isBranchesLoading() {
      return this.$apollo.queries.availableBranches.loading;
    },
    showBranchSwitcher() {
      return this.branches.length > 0 || this.page.searchTerm.length > 0;
    },
    searchPattern() {
      if (this.page.searchTerm === '') {
        return '*';
      }

      return `*${this.page.searchTerm}*`;
    },
  },
  methods: {
    // if there is no searchPattern, paginate by {paginationLimit} branches
    fetchNextBranches() {
      if (
        this.isBranchesLoading ||
        this.page.searchTerm.length > 0 ||
        this.branches.length === this.totalBranches
      ) {
        return;
      }

      this.page = {
        ...this.page,
        limit: this.paginationLimit,
        offset: this.page.offset + this.paginationLimit,
      };
    },
    async selectBranch(newBranch) {
      if (newBranch === this.currentBranch) {
        return;
      }

      await this.$apollo.getClient().writeQuery({
        query: getCurrentBranch,
        data: { currentBranch: newBranch },
      });

      const updatedPath = setUrlParams({ branch_name: newBranch });
      historyPushState(updatedPath);

      this.$emit('refetchContent');
    },
    setSearchTerm(newSearchTerm) {
      this.branches = [];
      this.page = {
        limit: newSearchTerm.trim() === '' ? this.paginationLimit : this.totalBranches,
        offset: 0,
        searchTerm: newSearchTerm.trim(),
      };
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="showBranchSwitcher"
    class="gl-ml-2"
    :header-text="$options.i18n.dropdownHeader"
    :text="currentBranch"
    icon="branch"
  >
    <gl-search-box-by-type :debounce="$options.inputDebounce" @input="setSearchTerm" />
    <gl-dropdown-section-header>
      {{ $options.i18n.title }}
    </gl-dropdown-section-header>

    <gl-infinite-scroll
      :fetched-items="branches.length"
      :total-items="totalBranches"
      :max-list-height="250"
      @bottomReached="fetchNextBranches"
    >
      <template #items>
        <gl-dropdown-item
          v-for="branch in branches"
          :key="branch"
          :is-checked="currentBranch === branch"
          :is-check-item="true"
          @click="selectBranch(branch)"
        >
          {{ branch }}
        </gl-dropdown-item>
      </template>
      <template #default>
        <gl-dropdown-item v-if="isBranchesLoading" key="loading">
          <gl-loading-icon size="md" />
        </gl-dropdown-item>
      </template>
    </gl-infinite-scroll>
  </gl-dropdown>
</template>
