<script>
import { mapGetters, mapState } from 'vuex';
import { sprintf, __ } from '~/locale';
import * as consts from '../../stores/modules/commit/constants';
import RadioGroup from './radio_group.vue';

export default {
  components: {
    RadioGroup,
  },
  computed: {
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapGetters(['hasChanges']),
    commitToCurrentBranchText() {
      return sprintf(
        __('Commit to %{branchName} branch'),
        { branchName: `<strong class="monospace">${this.currentBranchId}</strong>` },
        false,
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
    />
    <radio-group
      :value="$options.commitToNewBranchMR"
      :label="__('Create a new branch and merge request')"
      :show-input="true"
      :disabled="!!changedFiles.length && !!changedFiles.length"
    />
  </div>
</template>
