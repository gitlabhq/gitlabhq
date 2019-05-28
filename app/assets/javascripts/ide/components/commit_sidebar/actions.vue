<script>
import _ from 'underscore';
import { mapActions, mapState, mapGetters, createNamespacedHelpers } from 'vuex';
import { sprintf, __ } from '~/locale';
import consts from '../../stores/modules/commit/constants';
import RadioGroup from './radio_group.vue';

const { mapState: mapCommitState, mapGetters: mapCommitGetters } = createNamespacedHelpers(
  'commit',
);

export default {
  components: {
    RadioGroup,
  },
  computed: {
    ...mapState(['currentBranchId', 'changedFiles', 'stagedFiles']),
    ...mapCommitState(['commitAction', 'shouldCreateMR', 'shouldDisableNewMrOption']),
    ...mapGetters(['currentProject', 'currentBranch', 'currentMergeRequest']),
    ...mapCommitGetters(['shouldDisableNewMrOption']),
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
  watch: {
    disableMergeRequestRadio() {
      this.updateSelectedCommitAction();
    },
  },
  mounted() {
    this.updateSelectedCommitAction();
  },
  methods: {
    ...mapActions('commit', ['updateCommitAction', 'toggleShouldCreateMR']),
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
      <span class="ide-radio-label" v-html="commitToCurrentBranchText"> </span>
    </radio-group>
    <radio-group
      :value="$options.commitToNewBranch"
      :label="__('Create a new branch')"
      :show-input="true"
    />
    <hr class="my-2" />
    <label class="mb-0">
      <input
        :checked="shouldCreateMR"
        :disabled="shouldDisableNewMrOption"
        type="checkbox"
        @change="toggleShouldCreateMR"
      />
      <span class="prepend-left-10" :class="{ 'text-secondary': shouldDisableNewMrOption }">
        {{ __('Start a new merge request') }}
      </span>
    </label>
  </div>
</template>
