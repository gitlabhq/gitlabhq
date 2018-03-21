<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
import modal from '~/vue_shared/components/modal.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import commitFilesList from './commit_sidebar/list.vue';
import EmptyState from './commit_sidebar/empty_state.vue';
import Actions from './commit_sidebar/actions.vue';
import * as consts from '../stores/modules/commit/constants';

export default {
  components: {
    modal,
    icon,
    commitFilesList,
    EmptyState,
    Actions,
    LoadingButton,
  },
  directives: {
    tooltip,
  },
  props: {
    noChangesStateSvgPath: {
      type: String,
      required: true,
    },
    committedStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['stagedFiles', 'rightPanelCollapsed']),
    ...mapState('commit', ['commitMessage', 'submitCommitLoading']),
    ...mapGetters(['unstagedFiles']),
    ...mapGetters('commit', [
      'commitButtonDisabled',
      'discardDraftButtonDisabled',
      'branchName',
    ]),
  },
  methods: {
    ...mapActions('commit', [
      'updateCommitMessage',
      'discardDraft',
      'commitChanges',
      'updateCommitAction',
    ]),
    forceCreateNewBranch() {
      return this.updateCommitAction(consts.COMMIT_TO_NEW_BRANCH).then(() =>
        this.commitChanges(),
      );
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel-section"
  >
    <modal
      id="ide-create-branch-modal"
      :primary-button-label="__('Create new branch')"
      kind="success"
      :title="__('Branch has changed')"
      @submit="forceCreateNewBranch"
    >
      <template slot="body">
        {{ __(`This branch has changed since you started editing.
          Would you like to create a new branch?`) }}
      </template>
    </modal>
    <template
      v-if="unstagedFiles.length || stagedFiles.length"
    >
      <commit-files-list
        icon="unstaged"
        :title="__('Unstaged')"
        :file-list="unstagedFiles"
        action="stageAllChanges"
        :action-btn-text="__('Stage all')"
        item-action-component="stage-button"
      />
      <commit-files-list
        icon="staged"
        :title="__('Staged')"
        :file-list="stagedFiles"
        action="unstageAllChanges"
        :action-btn-text="__('Unstage all')"
        item-action-component="unstage-button"
        :show-toggle="false"
      />
      <form
        class="form-horizontal multi-file-commit-form"
        @submit.prevent.stop="commitChanges"
        v-if="!rightPanelCollapsed"
      >
        <div class="multi-file-commit-fieldset">
          <textarea
            class="form-control multi-file-commit-message"
            name="commit-message"
            :value="commitMessage"
            :placeholder="__('Write a commit message...')"
            @input="updateCommitMessage($event.target.value)"
          >
          </textarea>
        </div>
        <div class="clearfix prepend-top-15">
          <actions />
          <loading-button
            :loading="submitCommitLoading"
            :disabled="commitButtonDisabled"
            container-class="btn btn-success btn-sm pull-left"
            :label="__('Commit')"
            @click="commitChanges"
          />
          <button
            v-if="!discardDraftButtonDisabled"
            type="button"
            class="btn btn-default btn-sm pull-right"
            @click="discardDraft"
          >
            {{ __('Discard draft') }}
          </button>
        </div>
      </form>
    </template>
    <empty-state
      v-else
      :no-changes-state-svg-path="noChangesStateSvgPath"
      :committed-state-svg-path="committedStateSvgPath"
    />
  </div>
</template>
