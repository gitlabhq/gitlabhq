<script>
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { BRANCH_PAGINATION_LIMIT, DEFAULT_FAILURE } from '~/ci/pipeline_editor/constants';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import BranchSelector from '../shared/branch_selector.vue';

export default {
  i18n: {
    dropdownHeader: __('Switch branch'),
    fetchError: __('Unable to fetch branch list for this project.'),
  },
  components: {
    BranchSelector,
  },
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
      branchSelected: null,
      currentBranch: '',
    };
  },
  apollo: {
    currentBranch: {
      query: getCurrentBranch,
      update(data) {
        return data.workBranches.current.name;
      },
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
    async changeBranch(newBranch) {
      const updatedPath = setUrlParams({ branch_name: newBranch });
      visitUrl(updatedPath);
    },
    selectBranch(newBranch) {
      // If there are unsaved changes, we want to show the user
      // a modal to confirm what to do with these before changing
      // branches.
      if (this.hasUnsavedChanges) {
        this.branchSelected = newBranch;
        this.$emit('select-branch', newBranch);
      } else {
        this.changeBranch(newBranch);
      }
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
  <branch-selector
    :dropdown-header="$options.i18n.dropdownHeader"
    :current-branch-name="currentBranch"
    :pagination-limit="paginationLimit"
    @select-branch="selectBranch"
    @fetch-error="showFetchError"
  />
</template>
