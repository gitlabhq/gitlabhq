<script>
/* global Flash */
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';
import Service from '../services/repo_service';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';

export default {
  data() {
    return Store;
  },

  mixins: [RepoMixin],

  components: {
    PopupDialog,
  },

  computed: {
    showCommitable() {
      return this.isCommitable && this.changedFiles.length;
    },

    branchPaths() {
      return this.changedFiles.map(f => f.path);
    },

    cantCommitYet() {
      return !this.commitMessage || this.submitCommitsLoading;
    },

    filePluralize() {
      return this.changedFiles.length > 1 ? 'files' : 'file';
    },
  },

  methods: {
    changeBranchSubmit(status) {
      if (status) {
        this.showBranchChangeDialog = false;
        this.tryCommit(null, true, true);
      }
    },

    tryCommit(e, skipBranchCheck = false, newBranch = false) {
      const makeCommit = () => {
        // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
        const commitMessage = this.commitMessage;
        const actions = this.changedFiles.map(f => ({
          action: 'update',
          file_path: f.path,
          content: f.newContent,
        }));
        const branch = newBranch ? `${this.currentBranch}-${this.currentShortHash}` : this.currentBranch;
        const payload = {
          branch,
          commit_message: commitMessage,
          actions,
        };
        if (newBranch) {
          payload.start_branch = this.currentBranch;
        }
        this.submitCommitsLoading = true;
        Service.commitFiles(payload)
          .then(() => {
            this.reloadPage(branch);
            this.$emit('tryCommit:complete');
          })
          .catch(this.commitError);
      };

      if (skipBranchCheck) {
        makeCommit();
      } else {
        Store.setBranchHash()
        .then(() => {
          if (Store.branchChanged) {
            Store.showBranchChangeDialog = true;
            this.$emit('showBranchChangeDialog:enabled');
            return;
          }
          makeCommit();
        })
        .catch(this.commitError);
      }
    },

    commitError() {
      Flash('An error occurred while committing your changes');
    },

    reloadPage(branch) {
      this.resetCommitState();
      document.location.href = this.customBranchURL.replace('{{branch}}', branch);
    },

    resetCommitState() {
      this.submitCommitsLoading = false;
      this.openedFiles.map((f) => {
        const file = f;
        file.changed = false;
        return file;
      });
      this.changedFiles = [];
      this.commitMessage = '';
      this.editMode = false;
      window.scrollTo(0, 0);
    },
  },
};
</script>

<template>
<div
  v-if="showCommitable"
  id="commit-area">
  <popup-dialog
    v-if="showBranchChangeDialog"
    :primary-button-label="__('Create New Branch')"
    kind="primary"
    :title="__('Branch has changed')"
    :body="__('This branch has changed since your started editing. Would you like to create a new branch?')"
    @submit="changeBranchSubmit"
  />
  <form
    class="form-horizontal"
    @submit.prevent="tryCommit">
    <fieldset>
      <div class="form-group">
        <label class="col-md-4 control-label staged-files">
          Staged files ({{changedFiles.length}})
        </label>
        <div class="col-md-6">
          <ul class="list-unstyled changed-files">
            <li
              v-for="branchPath in branchPaths"
              :key="branchPath">
              <span class="help-block">
                {{branchPath}}
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
          ref="submitCommit"
          type="submit"
          :disabled="cantCommitYet"
          class="btn btn-success">
          <i
            v-if="submitCommitsLoading"
            class="fa fa-spinner fa-spin"
            aria-hidden="true"
            aria-label="loading">
          </i>
          <span class="commit-summary">
            Commit {{changedFiles.length}} {{filePluralize}}
          </span>
        </button>
      </div>
    </fieldset>
  </form>
</div>
</template>
