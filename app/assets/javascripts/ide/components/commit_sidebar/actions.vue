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
    },
  };
</script>

<template>
  <div class="append-bottom-15">
    <radio-group
      :value="COMMIT_TO_CURRENT_BRANCH"
      :label="`Commit to ${currentBranchId} branch`"
      :checked="true"
    />
    <radio-group
      :value="COMMIT_TO_NEW_BRANCH"
      label="Create a new branch"
      :show-input="true"
    />
    <radio-group
      :value="COMMIT_TO_NEW_BRANCH_MR"
      label="Create a new branch and merge request"
      :show-input="true"
    />
  </div>
</template>
