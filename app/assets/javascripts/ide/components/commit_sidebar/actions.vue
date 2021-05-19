<script>
import { GlSprintf } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapState, mapGetters, createNamespacedHelpers } from 'vuex';
import { s__ } from '~/locale';
import {
  COMMIT_TO_CURRENT_BRANCH,
  COMMIT_TO_NEW_BRANCH,
} from '../../stores/modules/commit/constants';
import NewMergeRequestOption from './new_merge_request_option.vue';
import RadioGroup from './radio_group.vue';

const { mapState: mapCommitState, mapActions: mapCommitActions } = createNamespacedHelpers(
  'commit',
);

export default {
  components: {
    GlSprintf,
    RadioGroup,
    NewMergeRequestOption,
  },
  computed: {
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapCommitState(['commitAction']),
    ...mapGetters(['currentBranch', 'emptyRepo', 'canPushToBranch']),
    currentBranchText() {
      return escape(this.currentBranchId);
    },
    containsStagedChanges() {
      return this.changedFiles.length > 0 && this.stagedFiles.length > 0;
    },
    shouldDefaultToCurrentBranch() {
      if (this.emptyRepo) {
        return true;
      }

      return this.canPushToBranch && !this.currentBranch?.default;
    },
  },
  watch: {
    containsStagedChanges() {
      this.updateSelectedCommitAction();
    },
  },
  mounted() {
    if (!this.commitAction) {
      this.updateSelectedCommitAction();
    }
  },
  methods: {
    ...mapCommitActions(['updateCommitAction']),
    updateSelectedCommitAction() {
      if (!this.currentBranch && !this.emptyRepo) {
        return;
      }

      if (this.shouldDefaultToCurrentBranch) {
        this.updateCommitAction(COMMIT_TO_CURRENT_BRANCH);
      } else {
        this.updateCommitAction(COMMIT_TO_NEW_BRANCH);
      }
    },
  },
  commitToCurrentBranch: COMMIT_TO_CURRENT_BRANCH,
  commitToNewBranch: COMMIT_TO_NEW_BRANCH,
  currentBranchPermissionsTooltip: s__(
    "IDE|This option is disabled because you don't have write permissions for the current branch.",
  ),
};
</script>

<template>
  <div class="gl-mb-5 ide-commit-options">
    <radio-group
      :value="$options.commitToCurrentBranch"
      :disabled="!canPushToBranch"
      :title="$options.currentBranchPermissionsTooltip"
      data-qa-selector="commit_to_current_branch_radio_container"
    >
      <span class="ide-option-label">
        <gl-sprintf :message="s__('IDE|Commit to %{branchName} branch')">
          <template #branchName>
            <strong class="monospace">{{ currentBranchText }}</strong>
          </template>
        </gl-sprintf>
      </span>
    </radio-group>
    <template v-if="!emptyRepo">
      <radio-group
        :value="$options.commitToNewBranch"
        :label="__('Create a new branch')"
        :show-input="true"
      />
      <new-merge-request-option />
    </template>
  </div>
</template>
