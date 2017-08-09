<script>
/* global Flash */
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';
import Helper from '../helpers/repo_helper';
import Service from '../services/repo_service';

const RepoCommitSection = {
  data: () => Store,

  mixins: [RepoMixin],

  computed: {

    showCommitable() {
      return isCommitable && changedFiles.length;
    },

    branchPaths() {
      const branch = this.currentBranch;
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
    makeCommit() {
      // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
      const branch = Store.currentBranch;
      const commitMessage = this.commitMessage;
      const actions = this.changedFiles.map(f => {
        return {
          action: 'update',
          file_path: f.path,
          content: f.newContent,
        };
      });
      const payload = {
        branch: Store.targetBranch,
        commit_message: commitMessage,
        actions,
      };
      Store.submitCommitsLoading = true;
      Service.commitFiles(payload, this.resetCommitState);
    },

    resetCommitState() {
      this.submitCommitsLoading = false;
      this.changedFiles = [];
      // this.openedFiles = [];
      this.commitMessage = '';
      this.editMode = false;
      window.scrollTo(0,0);
    },
  },
};

export default RepoCommitSection;
</script>

<template>
<div id="commit-area" v-if="showCommitable">
  <form class="form-horizontal">
    <fieldset>
      <div class="form-group">
        <label class="col-md-4 control-label staged-files">Staged files ({{changedFiles.length}})</label>
        <div class="col-md-4">
          <ul class="list-unstyled changed-files">
            <li v-for="file in branchPaths" :key="file.id">
              <span class="help-block">{{file}}</span>
            </li>
          </ul>
        </div>
      </div>
      <!-- Textarea
      -->
      <div class="form-group">
        <label class="col-md-4 control-label" for="commit-message">Commit message</label>
        <div class="col-md-4">
          <textarea class="form-control" id="commit-message" name="commit-message" v-model="commitMessage"></textarea>
        </div>
      </div>
      <!-- Button Drop Down
      -->
      <div class="form-group target-branch">
        <label class="col-md-4 control-label" for="target-branch">Target branch</label>
        <div class="col-md-4">
          <span class="help-block">{{targetBranch}}</span>
        </div>
      </div>
      <div class="col-md-offset-4 col-md-4">
        <button type="submit" :disabled="cantCommitYet" class="btn btn-success submit-commit" @click.prevent="makeCommit">
          <i class="fa fa-spinner fa-spin" v-if="submitCommitsLoading"></i>
          <span class="commit-summary">Commit {{changedFiles.length}} {{filePluralize}}</span>
        </button>
      </div>
    </fieldset>
  </form>
</div>
</template>
