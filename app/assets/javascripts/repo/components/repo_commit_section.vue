<script>
import Flash from '../../flash';
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';
import Service from '../services/repo_service';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';
import { visitUrl } from '../../lib/utils/url_utility';

export default {
  mixins: [RepoMixin],

  data() {
    return Store;
  },

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
    commitToNewBranch(status) {
      if (status) {
        this.showNewBranchDialog = false;
        this.tryCommit(null, true, true);
      } else {
        // reset the state
      }
    },

    makeCommit(newBranch) {
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
          this.resetCommitState();
          if (this.startNewMR) {
            this.redirectToNewMr(branch);
          } else {
            this.redirectToBranch(branch);
          }
        })
        .catch(() => {
          Flash('An error occurred while committing your changes');
        });
    },

    tryCommit(e, skipBranchCheck = false, newBranch = false) {
      if (skipBranchCheck) {
        this.makeCommit(newBranch);
      } else {
        Store.setBranchHash()
          .then(() => {
            if (Store.branchChanged) {
              Store.showNewBranchDialog = true;
              return;
            }
            this.makeCommit(newBranch);
          })
          .catch(() => {
            Flash('An error occurred while committing your changes');
          });
      }
    },

    redirectToNewMr(branch) {
      visitUrl(this.newMrTemplateUrl.replace('{{source_branch}}', branch));
    },

    redirectToBranch(branch) {
      visitUrl(this.customBranchURL.replace('{{branch}}', branch));
    },

    resetCommitState() {
      this.submitCommitsLoading = false;
      this.openedFiles = this.openedFiles.map((file) => {
        const f = file;
        f.changed = false;
        return f;
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
    v-if="showNewBranchDialog"
    :primary-button-label="__('Create new branch')"
    kind="primary"
    :title="__('Branch has changed')"
    :text="__('This branch has changed since you started editing. Would you like to create a new branch?')"
    @submit="commitToNewBranch"
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
            class="js-commit-loading-icon fa fa-spinner fa-spin"
            aria-hidden="true"
            aria-label="loading">
          </i>
          <span class="commit-summary">
            Commit {{changedFiles.length}} {{filePluralize}}
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
