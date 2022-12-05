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
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  BRANCH_PAGINATION_LIMIT,
  BRANCH_SEARCH_DEBOUNCE,
  DEFAULT_FAILURE,
} from '~/ci/pipeline_editor/constants';
import updateCurrentBranchMutation from '~/ci/pipeline_editor/graphql/mutations/client/update_current_branch.mutation.graphql';
import getAvailableBranchesQuery from '~/ci/pipeline_editor/graphql/queries/available_branches.query.graphql';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import getLastCommitBranch from '~/ci/pipeline_editor/graphql/queries/client/last_commit_branch.query.graphql';

export default {
  i18n: {
    dropdownHeader: __('Switch branch'),
    title: __('Branches'),
    fetchError: __('Unable to fetch branch list for this project.'),
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
    hasUnsavedChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
    paginationLimit: {
      type: Number,
      required: false,
      default: BRANCH_PAGINATION_LIMIT,
    },
    shouldLoadNewBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      availableBranches: [],
      branchSelected: null,
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
          offset: 0,
          projectFullPath: this.projectFullPath,
          ...this.availableBranchesVariables,
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
      update(data) {
        return data.workBranches.current.name;
      },
    },
    lastCommitBranch: {
      query: getLastCommitBranch,
      update(data) {
        return data.workBranches.lastCommit.name;
      },
      result({ data }) {
        if (data) {
          const { name: lastCommitBranch } = data.workBranches.lastCommit;
          if (lastCommitBranch === '' || this.availableBranches.includes(lastCommitBranch)) {
            return;
          }

          this.availableBranches.unshift(lastCommitBranch);
        }
      },
    },
  },
  computed: {
    availableBranchesVariables() {
      if (this.searchTerm.length > 0) {
        return {
          limit: this.totalBranches,
          searchPattern: `*${this.searchTerm}*`,
        };
      }

      return {
        limit: this.paginationLimit,
        searchPattern: '*',
      };
    },
    enableBranchSwitcher() {
      return this.availableBranches.length > 0 || this.searchTerm.length > 0;
    },
    isBranchesLoading() {
      return this.$apollo.queries.availableBranches.loading;
    },
  },
  watch: {
    shouldLoadNewBranch(flag) {
      if (flag) {
        this.changeBranch(this.branchSelected);
      }
    },
  },
  methods: {
    // if there is no searchPattern, paginate by {paginationLimit} branches
    fetchNextBranches() {
      if (
        this.isBranchesLoading ||
        this.searchTerm.length > 0 ||
        this.availableBranches.length >= this.totalBranches
      ) {
        return;
      }

      this.$apollo.queries.availableBranches
        .fetchMore({
          variables: {
            offset: this.pageCounter * this.paginationLimit,
          },
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
    async changeBranch(newBranch) {
      this.updateCurrentBranch(newBranch);
      const updatedPath = setUrlParams({ branch_name: newBranch });
      historyPushState(updatedPath);

      // refetching the content will cause a lot of components to re-render,
      // including the text editor which uses the commit sha to register the CI schema
      // so we need to make sure the currentBranch (and consequently, the commitSha) are updated first
      await this.$nextTick();
      this.$emit('refetchContent');
    },
    selectBranch(newBranch) {
      if (newBranch !== this.currentBranch) {
        // If there are unsaved changes, we want to show the user
        // a modal to confirm what to do with these before changing
        // branches.
        if (this.hasUnsavedChanges) {
          this.branchSelected = newBranch;
          this.$emit('select-branch', newBranch);
        } else {
          this.changeBranch(newBranch);
        }
      }
    },
    async setSearchTerm(newSearchTerm) {
      this.pageCounter = 0;
      this.searchTerm = newSearchTerm.trim();
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
    v-gl-tooltip.hover
    :title="$options.i18n.dropdownHeader"
    :header-text="$options.i18n.dropdownHeader"
    :text="currentBranch"
    :disabled="!enableBranchSwitcher"
    icon="branch"
    data-qa-selector="branch_selector_button"
    data-testid="branch-selector"
  >
    <gl-search-box-by-type :debounce="$options.inputDebounce" @input="setSearchTerm" />
    <gl-dropdown-section-header>
      {{ $options.i18n.title }}
    </gl-dropdown-section-header>

    <gl-infinite-scroll
      :fetched-items="availableBranches.length"
      :max-list-height="250"
      data-qa-selector="branch_menu_container"
      @bottomReached="fetchNextBranches"
    >
      <template #items>
        <gl-dropdown-item
          v-for="branch in availableBranches"
          :key="branch"
          :is-checked="currentBranch === branch"
          is-check-item
          data-qa-selector="branch_menu_item_button"
          @click="selectBranch(branch)"
        >
          {{ branch }}
        </gl-dropdown-item>
      </template>
      <template #default>
        <gl-dropdown-item v-if="isBranchesLoading" key="loading">
          <gl-loading-icon size="lg" />
        </gl-dropdown-item>
      </template>
    </gl-infinite-scroll>
  </gl-dropdown>
</template>
