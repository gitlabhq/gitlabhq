<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';
import { n__ } from '../../locale';

export default {
  components: {
    PopupDialog,
  },
  data() {
    return {
      showNewBranchDialog: false,
      submitCommitsLoading: false,
      startNewMR: false,
      commitMessage: '',
    };
  },
  computed: {
    ...mapState([
      'currentBranch',
    ]),
    ...mapGetters([
      'changedFiles',
    ]),
    commitButtonDisabled() {
      return !this.commitMessage || this.submitCommitsLoading;
    },
    commitButtonText() {
      return n__('Commit %d file', 'Commit %d files', this.changedFiles.length);
    },
  },
  methods: {
    ...mapActions([
      'checkCommitStatus',
      'commitChanges',
      'getTreeData',
    ]),
    makeCommit(newBranch = false) {
      const createNewBranch = newBranch || this.startNewMR;

      const payload = {
        branch: createNewBranch ? `${this.currentBranch}-${new Date().getTime().toString()}` : this.currentBranch,
        commit_message: this.commitMessage,
        actions: this.changedFiles.map(f => ({
          action: f.tempFile ? 'create' : 'update',
          file_path: f.path,
          content: f.content,
          encoding: f.base64 ? 'base64' : 'text',
        })),
        start_branch: createNewBranch ? this.currentBranch : undefined,
      };

      this.showNewBranchDialog = false;
      this.submitCommitsLoading = true;

      this.commitChanges({ payload, newMr: this.startNewMR })
        .then(() => {
          this.submitCommitsLoading = false;
          this.getTreeData();
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
            this.showNewBranchDialog = true;
          } else {
            this.makeCommit();
          }
        })
        .catch(() => {
          this.submitCommitsLoading = false;
        });
    },
  },
};
</script>

<template>
<div id="commit-area">
  <popup-dialog
    v-if="showNewBranchDialog"
    :primary-button-label="__('Create new branch')"
    kind="primary"
    :title="__('Branch has changed')"
    :text="__('This branch has changed since you started editing. Would you like to create a new branch?')"
    @toggle="showNewBranchDialog = false"
    @submit="makeCommit(true)"
  />
  <form
    class="form-horizontal"
    @submit.prevent="tryCommit()">
    <fieldset>
      <div class="form-group">
        <label class="col-md-4 control-label staged-files">
          Staged files ({{changedFiles.length}})
        </label>
        <div class="col-md-6">
          <ul class="list-unstyled changed-files">
            <li
              v-for="(file, index) in changedFiles"
              :key="index">
              <span class="help-block">
                {{ file.path }}
              </span>
            </li>
          </ul>
        </div>
      </div>
      <div class="form-group">
        <label
          class="col-md-4 control-label"
          for="commit-message">
          Commit message
        </label>
        <div class="col-md-6">
          <textarea
            id="commit-message"
            class="form-control"
            name="commit-message"
            v-model="commitMessage">
          </textarea>
        </div>
      </div>
      <div class="form-group target-branch">
        <label
          class="col-md-4 control-label"
          for="target-branch">
          Target branch
        </label>
        <div class="col-md-6">
          <span class="help-block">
            {{currentBranch}}
          </span>
        </div>
      </div>
      <div class="col-md-offset-4 col-md-6">
        <button
          type="submit"
          :disabled="commitButtonDisabled"
          class="btn btn-success">
          <i
            v-if="submitCommitsLoading"
            class="js-commit-loading-icon fa fa-spinner fa-spin"
            aria-hidden="true"
            aria-label="loading">
          </i>
          <span class="commit-summary">
            {{ commitButtonText }}
          </span>
        </button>
      </div>
      <div class="col-md-offset-4 col-md-6">
        <div class="checkbox">
          <label>
            <input type="checkbox" v-model="startNewMR">
            <span>Start a <strong>new merge request</strong> with these changes</span>
          </label>
        </div>
      </div>
    </fieldset>
  </form>
</div>
</template>
