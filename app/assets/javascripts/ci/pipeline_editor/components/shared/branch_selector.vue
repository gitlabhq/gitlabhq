<script>
import { GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { BRANCH_PAGINATION_LIMIT, BRANCH_SEARCH_DEBOUNCE } from '~/ci/pipeline_editor/constants';
import getAvailableBranchesQuery from '~/ci/pipeline_editor/graphql/queries/available_branches.query.graphql';
import getLastCommitBranch from '~/ci/pipeline_editor/graphql/queries/client/last_commit_branch.query.graphql';

export default {
  inputDebounce: BRANCH_SEARCH_DEBOUNCE,
  components: {
    GlCollapsibleListbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectFullPath', 'totalBranches'],
  props: {
    dropdownHeader: {
      type: String,
      required: true,
    },
    currentBranchName: {
      type: String,
      required: true,
    },
    paginationLimit: {
      type: Number,
      required: false,
      default: BRANCH_PAGINATION_LIMIT,
    },
  },
  emits: ['select-branch', 'fetch-error'],
  data() {
    return {
      availableBranches: [],
      pageCounter: 0,
      searchTerm: '',
      currentBranch: this.currentBranchName,
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
        this.emitFetchError();
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    infiniteScrollEnabled() {
      return this.availableBranches.length > 0;
    },
    branchesData() {
      return this.availableBranches.map((branch) => ({
        text: branch,
        value: branch,
      }));
    },
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
    isBranchSwitcherEnabled() {
      return this.availableBranches.length > 0 || this.searchTerm.length > 0;
    },
    areBranchesLoading() {
      return this.$apollo.queries.availableBranches.loading;
    },
  },
  watch: {
    currentBranchName: {
      immediate: true,
      async handler(newVal, oldVal) {
        if (newVal === oldVal) {
          return;
        }
        this.currentBranch = this.currentBranchName;
      },
    },
  },
  methods: {
    // if there is no searchPattern, paginate by {paginationLimit} branches
    fetchNextBranches() {
      if (
        this.areBranchesLoading ||
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
        .catch(this.emitFetchError);
    },
    selectBranch(newBranch) {
      this.$emit('select-branch', newBranch);
    },

    async setSearchTerm(newSearchTerm) {
      this.pageCounter = 0;
      this.searchTerm = newSearchTerm.trim();
    },
    emitFetchError() {
      this.$emit('fetch-error');
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="currentBranch"
    v-gl-tooltip.hover
    searchable
    :items="branchesData"
    :title="dropdownHeader"
    :header-text="dropdownHeader"
    :toggle-text="currentBranch"
    :disabled="!isBranchSwitcherEnabled"
    icon="branch"
    data-testid="branch-selector"
    :no-results-text="__('No matching results')"
    :infinite-scroll-loading="areBranchesLoading"
    :infinite-scroll="infiniteScrollEnabled"
    @select="selectBranch"
    @search="setSearchTerm"
    @bottom-reached="fetchNextBranches"
  />
</template>
