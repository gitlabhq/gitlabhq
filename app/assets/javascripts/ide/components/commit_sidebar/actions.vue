<script>
  import { mapState } from 'vuex';
  import * as consts from '../../stores/modules/commit/constants';
  import RadioGroup from './radio_group.vue';

  export default {
    components: {
      RadioGroup,
    },
    data() {
      return {
        COMMIT_TO_CURRENT_BRANCH: consts.COMMIT_TO_CURRENT_BRANCH,
        COMMIT_TO_NEW_BRANCH: consts.COMMIT_TO_NEW_BRANCH,
        COMMIT_TO_NEW_BRANCH_MR: consts.COMMIT_TO_NEW_BRANCH_MR,
      };
    },
    computed: {
      ...mapState([
        'currentBranchId',
      ]),
      newMergeRequestHelpText() {
        return `Creates a new branch from ${this.currentBranchId} and re-directs to create a new merge request`;
      },
    },
  };
</script>

<template>
  <div class="append-bottom-15 ide-commit-radios">
    <radio-group
      :value="COMMIT_TO_CURRENT_BRANCH"
      :checked="true"
    >
      <span
        v-html="`Commit to <strong>${currentBranchId}</strong> branch`"
      >
      </span>
    </radio-group>
    <radio-group
      :value="COMMIT_TO_NEW_BRANCH"
      label="Create a new branch"
      :show-input="true"
      :help-text="`Creates a new branch from ${currentBranchId}`"
    />
    <radio-group
      :value="COMMIT_TO_NEW_BRANCH_MR"
      label="Create a new branch and merge request"
      :show-input="true"
      :help-text="newMergeRequestHelpText"
    />
  </div>
</template>
