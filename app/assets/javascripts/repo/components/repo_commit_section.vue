<script>
/* global Flash */
import Store from '../stores/repo_store';
import Api from '../../api';
import RepoMixin from '../mixins/repo_mixin';
import Helper from '../helpers/repo_helper';

const RepoCommitSection = {
  data: () => Store,

  mixins: [RepoMixin],

  computed: {
    branchPaths() {
      const branch = Helper.getBranch();
      return this.changedFiles.map(f => Helper.getFilePathFromFullPath(f.url, branch));
    },

    cantCommitYet() {
      return !commitMessage || submitCommitsLoading;
    },

    filePluralize() {
      return this.changedFiles.length > 1 ? 'files' : 'file';
    },
  },

  methods: {
    makeCommit() {
      // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
      const branch = Helper.getBranch();
      const commitMessage = this.commitMessage;
      const actions = this.changedFiles.map(f => ({
        action: 'update',
        file_path: Helper.getFilePathFromFullPath(f.url, branch),
        content: f.newContent,
      }));
      const payload = {
        branch: Store.targetBranch,
        commit_message: commitMessage,
        actions,
      };
      Store.submitCommitsLoading = true;
      Api.commitMultiple(Store.projectId, payload, (data) => {
        Store.submitCommitsLoading = false;
        Flash(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');
        this.changedFiles = [];
        this.openedFiles = [];
        this.commitMessage = '';
        this.editMode = false;
        $('html, body').animate({ scrollTop: 0 }, 'fast');
      });
    },
  },
};

export default RepoCommitSection;
</script>

<template>
<div id="commit-area" v-if="isCommitable && changedFiles.length" >
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
