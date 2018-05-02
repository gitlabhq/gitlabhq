<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import CommitFilesList from './commit_sidebar/list.vue';
import EmptyState from './commit_sidebar/empty_state.vue';
import * as consts from '../stores/modules/commit/constants';
import { activityBarViews } from '../constants';

export default {
  components: {
    DeprecatedModal,
    Icon,
    CommitFilesList,
    EmptyState,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapState(['changedFiles', 'stagedFiles']),
    ...mapGetters(['lastOpenedFile', 'hasChanges']),
  },
  watch: {
    hasChanges() {
      if (!this.hasChanges) {
        this.updateActivityBarView(activityBarViews.edit);
      }
    },
  },
  mounted() {
    if (this.lastOpenedFile) {
      this.openPendingTab({
        file: this.lastOpenedFile,
      })
        .then(changeViewer => {
          if (changeViewer) {
            this.updateViewer('diff');
          }
        })
        .catch(e => {
          throw e;
        });
    }
  },
  methods: {
    ...mapActions(['openPendingTab', 'updateViewer', 'updateActivityBarView']),
    ...mapActions('commit', ['commitChanges', 'updateCommitAction']),
    forceCreateNewBranch() {
      return this.updateCommitAction(consts.COMMIT_TO_NEW_BRANCH).then(() => this.commitChanges());
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel-section"
  >
    <deprecated-modal
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
    </deprecated-modal>
    <template
      v-if="changedFiles.length || stagedFiles.length"
    >
      <commit-files-list
        class="is-first"
        icon-name="unstaged"
        :title="__('Unstaged')"
        :file-list="changedFiles"
        action="stageAllChanges"
        :action-btn-text="__('Stage all')"
        item-action-component="stage-button"
      />
      <commit-files-list
        icon-name="staged"
        :title="__('Staged')"
        :file-list="stagedFiles"
        action="unstageAllChanges"
        :action-btn-text="__('Unstage all')"
        item-action-component="unstage-button"
        :staged-list="true"
      />
    </template>
    <empty-state
      v-else
    />
  </div>
</template>
