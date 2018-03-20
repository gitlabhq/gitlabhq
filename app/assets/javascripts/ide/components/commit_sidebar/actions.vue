<script>
  import { mapState } from 'vuex';
  import { sprintf, __ } from '~/locale';
  import * as consts from '../../stores/modules/commit/constants';
  import RadioGroup from './radio_group.vue';

  export default {
    components: {
      RadioGroup,
    },
    computed: {
      ...mapState([
        'currentBranchId',
      ]),
      newMergeRequestHelpText() {
        return sprintf(
          __('Creates a new branch from %{branchName} and re-directs to create a new merge request'),
          { branchName: this.currentBranchId },
        );
      },
      commitToCurrentBranchText() {
        return sprintf(
          __('Commit to %{branchName} branch'),
          { branchName: `<strong>${this.currentBranchId}</strong>` },
          false,
        );
      },
      commitToNewBranchText() {
        return sprintf(
          __('Creates a new branch from %{branchName}'),
          { branchName: this.currentBranchId },
        );
      },
    },
    commitToCurrentBranch: consts.COMMIT_TO_CURRENT_BRANCH,
    commitToNewBranch: consts.COMMIT_TO_NEW_BRANCH,
    commitToNewBranchMR: consts.COMMIT_TO_NEW_BRANCH_MR,
  };
</script>

<template>
  <div class="append-bottom-15 ide-commit-radios">
    <radio-group
      :value="$options.commitToCurrentBranch"
      :checked="true"
    >
      <span
        v-html="commitToCurrentBranchText"
      >
      </span>
    </radio-group>
    <radio-group
      :value="$options.commitToNewBranch"
      :label="__('Create a new branch')"
      :show-input="true"
      :help-text="commitToNewBranchText"
    />
    <radio-group
      :value="$options.commitToNewBranchMR"
      :label="__('Create a new branch and merge request')"
      :show-input="true"
      :help-text="newMergeRequestHelpText"
    />
  </div>
</template>
