<script>
import _ from 'underscore';
import { mapActions, mapState, mapGetters } from 'vuex';
import { sprintf, __ } from '~/locale';
import * as consts from '../../stores/modules/commit/constants';
import RadioGroup from './radio_group.vue';

export default {
  components: {
    RadioGroup,
  },
  computed: {
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapGetters(['currentProject']),
    commitToCurrentBranchText() {
      return sprintf(
        __('Commit to %{branchName} branch'),
        { branchName: `<strong class="monospace">${_.escape(this.currentBranchId)}</strong>` },
        false,
      );
    },
    disableMergeRequestRadio() {
      return this.changedFiles.length > 0 && this.stagedFiles.length > 0;
    },
  },
  mounted() {
    if (this.disableMergeRequestRadio) {
      this.updateCommitAction(consts.COMMIT_TO_CURRENT_BRANCH);
    }
  },
  methods: {
    ...mapActions('commit', ['updateCommitAction']),
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
      :disabled="disableMergeRequestRadio"
    />
  </div>
</template>
