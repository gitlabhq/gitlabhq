<script>
import _ from 'underscore';
import { mapState, mapGetters, createNamespacedHelpers } from 'vuex';
import { sprintf, __ } from '~/locale';
import consts from '../../stores/modules/commit/constants';
import RadioGroup from './radio_group.vue';
import NewMergeRequestOption from './new_merge_request_option.vue';

const { mapState: mapCommitState, mapActions: mapCommitActions } = createNamespacedHelpers(
  'commit',
);

export default {
  components: {
    RadioGroup,
    NewMergeRequestOption,
  },
  computed: {
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapCommitState(['commitAction']),
    ...mapGetters(['currentBranch']),
    commitToCurrentBranchText() {
      return sprintf(
        __('Commit to %{branchName} branch'),
        { branchName: `<strong class="monospace">${_.escape(this.currentBranchId)}</strong>` },
        false,
      );
    },
    containsStagedChanges() {
      return this.changedFiles.length > 0 && this.stagedFiles.length > 0;
    },
  },
  watch: {
    containsStagedChanges() {
      this.updateSelectedCommitAction();
    },
  },
  mounted() {
    this.updateSelectedCommitAction();
  },
  methods: {
    ...mapCommitActions(['updateCommitAction']),
    updateSelectedCommitAction() {
      if (!this.currentBranch) {
        return;
      }

      const { can_push: canPush = false, default: isDefault = false } = this.currentBranch;

      if (canPush && !isDefault) {
        this.updateCommitAction(consts.COMMIT_TO_CURRENT_BRANCH);
      } else {
        this.updateCommitAction(consts.COMMIT_TO_NEW_BRANCH);
      }
    },
  },
  commitToCurrentBranch: consts.COMMIT_TO_CURRENT_BRANCH,
  commitToNewBranch: consts.COMMIT_TO_NEW_BRANCH,
  currentBranchPermissionsTooltip: __(
    "This option is disabled as you don't have write permissions for the current branch",
  ),
};
</script>

<template>
  <div class="append-bottom-15 ide-commit-options">
    <radio-group
      :value="$options.commitToCurrentBranch"
      :disabled="currentBranch && !currentBranch.can_push"
      :title="$options.currentBranchPermissionsTooltip"
    >
      <span
        class="ide-radio-label"
        data-qa-selector="commit_to_current_branch_radio"
        v-html="commitToCurrentBranchText"
      ></span>
    </radio-group>
    <radio-group
      :value="$options.commitToNewBranch"
      :label="__('Create a new branch')"
      :show-input="true"
    />
    <new-merge-request-option />
  </div>
</template>
