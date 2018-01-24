<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import tooltip from '../../vue_shared/directives/tooltip';
import icon from '../../vue_shared/components/icon.vue';
import modal from '../../vue_shared/components/modal.vue';
import commitFilesList from './commit_sidebar/list.vue';

export default {
  components: {
    modal,
    icon,
    commitFilesList,
  },
  directives: {
    tooltip,
  },
  data() {
    return {
      showNewBranchModal: false,
      submitCommitsLoading: false,
      startNewMR: false,
      commitMessage: '',
    };
  },
  computed: {
    ...mapState([
      'currentProjectId',
      'currentBranchId',
      'rightPanelCollapsed',
    ]),
    ...mapGetters([
      'changedFiles',
    ]),
    commitButtonDisabled() {
      return this.commitMessage === '' || this.submitCommitsLoading || !this.changedFiles.length;
    },
    commitMessageCount() {
      return this.commitMessage.length;
    },
  },
  methods: {
    ...mapActions([
      'checkCommitStatus',
      'commitChanges',
      'getTreeData',
      'setPanelCollapsedStatus',
    ]),
    makeCommit(newBranch = false) {
      const createNewBranch = newBranch || this.startNewMR;

      const payload = {
        branch: createNewBranch ? `${this.currentBranchId}-${new Date().getTime().toString()}` : this.currentBranchId,
        commit_message: this.commitMessage,
        actions: this.changedFiles.map(f => ({
          action: f.tempFile ? 'create' : 'update',
          file_path: f.path,
          content: f.content,
          encoding: f.base64 ? 'base64' : 'text',
        })),
        start_branch: createNewBranch ? this.currentBranchId : undefined,
      };

      this.showNewBranchModal = false;
      this.submitCommitsLoading = true;

      this.commitChanges({ payload, newMr: this.startNewMR })
        .then(() => {
          this.submitCommitsLoading = false;
          this.commitMessage = '';
          this.startNewMR = false;
        })
        .catch(() => {
          this.submitCommitsLoading = false;
        });
    },
    tryCommit() {
      this.submitCommitsLoading = true;

      this.checkCommitStatus()
        .then((branchChanged) => {
          if (branchChanged) {
            this.showNewBranchModal = true;
          } else {
            this.makeCommit();
          }
        })
        .catch(() => {
          this.submitCommitsLoading = false;
        });
    },
    toggleCollapsed() {
      this.setPanelCollapsedStatus({
        side: 'right',
        collapsed: !this.rightPanelCollapsed,
      });
    },
  },
};
</script>

<template>
<div class="multi-file-commit-panel-section">
  <modal
    v-if="showNewBranchModal"
    :primary-button-label="__('Create new branch')"
    kind="primary"
    :title="__('Branch has changed')"
    :text="__('This branch has changed since you started editing. Would you like to create a new branch?')"
    @cancel="showNewBranchModal = false"
    @submit="makeCommit(true)"
  />
  <commit-files-list
    title="Staged"
    :file-list="changedFiles"
    :collapsed="rightPanelCollapsed"
    @toggleCollapsed="toggleCollapsed"
  />
  <form
    class="form-horizontal multi-file-commit-form"
    @submit.prevent="tryCommit"
    v-if="!rightPanelCollapsed"
  >
    <div class="multi-file-commit-fieldset">
      <textarea
        class="form-control multi-file-commit-message"
        name="commit-message"
        v-model="commitMessage"
        placeholder="Commit message"
      >
      </textarea>
    </div>
    <div class="multi-file-commit-fieldset">
      <label
        v-tooltip
        title="Create a new merge request with these changes"
        data-container="body"
        data-placement="top"
      >
        <input
          type="checkbox"
          v-model="startNewMR"
        />
        Merge Request
      </label>
      <button
        type="submit"
        :disabled="commitButtonDisabled"
        class="btn btn-default btn-sm append-right-10 prepend-left-10"
        :class="{ disabled: submitCommitsLoading }"
      >
        <i
          v-if="submitCommitsLoading"
          class="js-commit-loading-icon fa fa-spinner fa-spin"
          aria-hidden="true"
          aria-label="loading"
        >
        </i>
        Commit
      </button>
      <div
        class="multi-file-commit-message-count"
      >
        {{ commitMessageCount }}
      </div>
    </div>
  </form>
</div>
</template>
