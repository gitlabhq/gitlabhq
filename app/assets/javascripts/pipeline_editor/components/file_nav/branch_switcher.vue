<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlInfiniteScroll,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlTooltipDirective,
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
import updateCurrentBranchMutation from '~/pipeline_editor/graphql/mutations/update_current_branch.mutation.graphql';
import getAvailableBranchesQuery from '~/pipeline_editor/graphql/queries/available_branches.graphql';
import getCurrentBranchQuery from '~/pipeline_editor/graphql/queries/client/current_branch.graphql';
import getLastCommitBranchQuery from '~/pipeline_editor/graphql/queries/client/last_commit_branch.query.graphql';

export default {
  i18n: {
    dropdownHeader: s__('Switch branch'),
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
  directives: {
    GlTooltip: GlTooltipDirective,
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
      lastCommitBranch: '',
    };
  },
  apollo: {
    availableBranches: {
      query: getAvailableBranchesQuery,
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
      query: getCurrentBranchQuery,
    },
    lastCommitBranch: {
      query: getLastCommitBranchQuery,
      result({ data: { lastCommitBranch } }) {
        if (lastCommitBranch === '' || this.availableBranches.includes(lastCommitBranch)) {
          return;
        }
        this.availableBranches.unshift(lastCommitBranch);
      },
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
    availableBranchesQueryVars(varsOverride = {}) {
      if (this.searchTerm.length > 0) {
        return {
          limit: this.totalBranches,
          offset: 0,
          projectFullPath: this.projectFullPath,
          searchPattern: `*${this.searchTerm}*`,
          ...varsOverride,
        };
      }

      return {
        limit: this.paginationLimit,
        offset: this.pageCounter * this.paginationLimit,
        projectFullPath: this.projectFullPath,
        searchPattern: '*',
        ...varsOverride,
      };
    },
    // if there is no searchPattern, paginate by {paginationLimit} branches
    fetchNextBranches() {
      if (
        this.isBranchesLoading ||
        this.searchTerm.length > 0 ||
        this.branches.length >= this.totalBranches
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

      this.updateCurrentBranch(newBranch);
      const updatedPath = setUrlParams({ branch_name: newBranch });
      historyPushState(updatedPath);

      this.$emit('updateCommitSha', { newBranch });

      // refetching the content will cause a lot of components to re-render,
      // including the text editor which uses the commit sha to register the CI schema
      // so we need to make sure the commit sha is updated first
      await this.$nextTick();
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
          query: getAvailableBranchesQuery,
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
    updateCurrentBranch(currentBranch) {
      this.$apollo.mutate({
        mutation: updateCurrentBranchMutation,
        variables: { currentBranch },
      });
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="showBranchSwitcher"
    v-gl-tooltip.hover
    :title="$options.i18n.dropdownHeader"
    :header-text="$options.i18n.dropdownHeader"
    :text="currentBranch"
    icon="branch"
    data-qa-selector="branch_selector_button"
  >
    <gl-search-box-by-type :debounce="$options.inputDebounce" @input="setSearchTerm" />
    <gl-dropdown-section-header>
      {{ $options.i18n.title }}
    </gl-dropdown-section-header>

    <gl-infinite-scroll
      :fetched-items="branches.length"
      :max-list-height="250"
      @bottomReached="fetchNextBranches"
    >
      <template #items>
        <gl-dropdown-item
          v-for="branch in branches"
          :key="branch"
          :is-checked="currentBranch === branch"
          :is-check-item="true"
          data-qa-selector="menu_branch_button"
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
