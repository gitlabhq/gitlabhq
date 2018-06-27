<script>
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
    ...mapGetters(['currentProject', 'currentBranch']),
    commitToCurrentBranchText() {
      return sprintf(
        __('Commit to %{branchName} branch'),
        { branchName: `<strong class="monospace">${this.currentBranchId}</strong>` },
        false,
      );
    },
    disableMergeRequestRadio() {
      return this.changedFiles.length > 0 && this.stagedFiles.length > 0;
    },
  },
  watch: {
    disableMergeRequestRadio() {
      this.updateSelectedCommitAction();
    },
  },
  mounted() {
    this.updateSelectedCommitAction();
  },
  methods: {
    ...mapActions('commit', ['updateCommitAction']),
    updateSelectedCommitAction() {
      if (this.currentBranch && !this.currentBranch.can_push) {
        this.updateCommitAction(consts.COMMIT_TO_NEW_BRANCH);
      } else if (this.disableMergeRequestRadio) {
        this.updateCommitAction(consts.COMMIT_TO_CURRENT_BRANCH);
      }
    },
  },
  commitToCurrentBranch: consts.COMMIT_TO_CURRENT_BRANCH,
  commitToNewBranch: consts.COMMIT_TO_NEW_BRANCH,
  commitToNewBranchMR: consts.COMMIT_TO_NEW_BRANCH_MR,
  currentBranchPermissionsTooltip: __(
    "This option is disabled as you don't have write permissions for the current branch",
  ),
};
</script>

<template>
  <div class="append-bottom-15 ide-commit-radios">
    <radio-group
      :value="$options.commitToCurrentBranch"
      :disabled="currentBranch && !currentBranch.can_push"
      :title="$options.currentBranchPermissionsTooltip"
    >
      <span
        class="ide-radio-label"
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
      :title="__('This option is disabled while you still have unstaged changes')"
      :show-input="true"
      :disabled="disableMergeRequestRadio"
    />
  </div>
</template>
