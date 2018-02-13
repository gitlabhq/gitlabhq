<script>
  import { mapActions, mapState, mapGetters } from 'vuex';
  import * as consts from '../../stores/modules/commit/constants';

  export default {
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
      ...mapState('commit', [
        'commitAction',
      ]),
      ...mapGetters('commit', [
        'newBranchName',
      ]),
    },
    methods: {
      ...mapActions('commit', [
        'updateCommitAction',
        'updateBranchName',
      ]),
    },
  };
</script>

<template>
  <div>
    <fieldset>
      <label>
        <input
          type="radio"
          name="commit-action"
          :value="COMMIT_TO_CURRENT_BRANCH"
          @change="updateCommitAction($event.target.value)"
          checked
        />
        Commit to <strong>{{ currentBranchId }}</strong> branch
      </label>
    </fieldset>
    <fieldset>
      <label>
        <input
          type="radio"
          name="commit-action"
          :value="COMMIT_TO_NEW_BRANCH"
          @change="updateCommitAction($event.target.value)"
        />
        Create a new branch
      </label>
      <template v-if="commitAction === '2'">
        <input
          type="text"
          class="form-control input-sm"
          :placeholder="newBranchName"
          @input="updateBranchName($event.target.value)"
        />
      </template>
    </fieldset>
    <fieldset>
      <label>
        <input
          type="radio"
          name="commit-action"
          :value="COMMIT_TO_NEW_BRANCH_MR"
          @change="updateCommitAction($event.target.value)"
        />
        Create a new branch and merge request
      </label>
    </fieldset>
  </div>
</template>
