<script>
<<<<<<< HEAD
import { mapState } from 'vuex';
=======
import { mapActions, mapState, mapGetters } from 'vuex';
>>>>>>> master
import { sprintf, __ } from '~/locale';
import * as consts from '../../stores/modules/commit/constants';
import RadioGroup from './radio_group.vue';

export default {
  components: {
    RadioGroup,
  },
  computed: {
<<<<<<< HEAD
    ...mapState(['currentBranchId']),
=======
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapGetters(['currentProject']),
>>>>>>> master
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
      v-if="currentProject.merge_requests_enabled"
      :value="$options.commitToNewBranchMR"
      :label="__('Create a new branch and merge request')"
      :show-input="true"
    />
  </div>
</template>
