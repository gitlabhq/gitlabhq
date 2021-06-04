<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlInfiniteScroll,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { produce } from 'immer';
import { fetchPolicies } from '~/lib/graphql';
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
      availableBranches: [],
      filteredBranches: [],
      isSearchingBranches: false,
      pageLimit: this.paginationLimit,
      pageCounter: 0,
      searchTerm: '',
    };
  },
  apollo: {
    availableBranches: {
      query: getAvailableBranches,
      variables() {
        return {
          limit: this.paginationLimit,
          offset: 0,
          projectFullPath: this.projectFullPath,
          searchPattern: '*',
        };
      },
      update(data) {
        return data.project?.repository?.branchNames || [];
      },
      result() {
        this.pageCounter += 1;
      },
      error() {
        this.showFetchError();
      },
    },
    currentBranch: {
      query: getCurrentBranch,
    },
  },
  computed: {
    branches() {
      return this.searchTerm.length > 0 ? this.filteredBranches : this.availableBranches;
    },
    isBranchesLoading() {
      return this.$apollo.queries.availableBranches.loading || this.isSearchingBranches;
    },
    showBranchSwitcher() {
      return this.branches.length > 0 || this.searchTerm.length > 0;
    },
  },
  methods: {
    availableBranchesQueryVars() {
      if (this.searchTerm.length > 0) {
        return {
          limit: this.totalBranches,
          offset: 0,
          projectFullPath: this.projectFullPath,
          searchPattern: `*${this.searchTerm}*`,
        };
      }

      return {
        limit: this.paginationLimit,
        offset: this.pageCounter * this.paginationLimit,
        projectFullPath: this.projectFullPath,
        searchPattern: '*',
      };
    },
    // if there is no searchPattern, paginate by {paginationLimit} branches
    fetchNextBranches() {
      if (
        this.isBranchesLoading ||
        this.searchTerm.length > 0 ||
        this.branches.length === this.totalBranches
      ) {
        return;
      }

      this.$apollo.queries.availableBranches
        .fetchMore({
          variables: this.availableBranchesQueryVars(),
          updateQuery(previousResult, { fetchMoreResult }) {
            const previousBranches = previousResult.project.repository.branchNames;
            const newBranches = fetchMoreResult.project.repository.branchNames;

            return produce(fetchMoreResult, (draftData) => {
              draftData.project.repository.branchNames = previousBranches.concat(newBranches);
            });
          },
        })
        .catch(this.showFetchError);
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
    async setSearchTerm(newSearchTerm) {
      this.pageCounter = 0;
      this.searchTerm = newSearchTerm.trim();

      if (this.searchTerm === '') {
        this.pageLimit = this.paginationLimit;
        return;
      }

      this.isSearchingBranches = true;
      const fetchResults = await this.$apollo
        .query({
          query: getAvailableBranches,
          fetchPolicy: fetchPolicies.NETWORK_ONLY,
          variables: this.availableBranchesQueryVars(),
        })
        .catch(this.showFetchError);

      this.isSearchingBranches = false;
      this.filteredBranches = fetchResults?.data?.project?.repository?.branchNames || [];
    },
    showFetchError() {
      this.$emit('showError', {
        type: DEFAULT_FAILURE,
        reasons: [this.$options.i18n.fetchError],
      });
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="showBranchSwitcher"
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
