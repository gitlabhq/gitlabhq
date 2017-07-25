<script>
import Vue from 'vue';
import Store from './repo_store';
import Api from '../api'

const RepoCommitSection = {
  data: () => Store,
  
  methods: {
    makeCommit() {
      // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
      // branch  string
      // commit_message  string
      // actions[]
      // author_email
      // author_name
      const branch = $("button.dropdown-menu-toggle").attr('data-ref');
      const commitMessage = this.commitMessage;
      const actions = this.changedFiles.map(f => {
          const filePath = f.url.split(branch)[1];
          return {
            action: 'update',
            file_path: filePath,
            content: f.newContent,
          };
      });
      const payload = {
        branch: branch,
        commit_message: commitMessage,
        actions: actions,
      }
      Api.commitMultiple(Store.projectId, payload, (data) => {
        console.log('got back', data);
      }, Store.tempPrivateToken);
    }
  },

  computed: {
    changedFiles() {
      const changedFileList = this.openedFiles
      .filter(file => file.changed);
      return changedFileList;
    },
  },
}

export default RepoCommitSection;
</script>

<template>
<div id="commit-area" v-if="isCommitable && changedFiles.length" >
  <form class="form-horizontal">
    <fieldset>
      <div class="form-group">
        <label class="col-md-4 control-label">Staged files ({{changedFiles.length}})</label>
        <div class="col-md-4">
          <ul class="list-unstyled">
            <li v-for="file in changedFiles">
              <span class="help-block">
                {{file.url}}
              </span>
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
      <div class="form-group">
        <label class="col-md-4 control-label" for="target-branch">Target branch</label>
        <div class="col-md-4">
          <div class="input-group">
            <div class="input-group-btn">
              <button class="btn btn-default dropdown-toggle" data-toggle="dropdown" type="button">
                Action
                <i class="fa fa-caret-down"></i>
              </button>
              <ul class="dropdown-menu pull-right">
                <li>
                  <a href="#">Target branch</a>
                </li>
                <li>
                  <a href="#">Create my own branch</a>
                </li>
              </ul>
            </div>
            <input class="form-control" id="target-branch" name="target-branch" placeholder="placeholder" type="text"></input>
          </div>
        </div>
      </div>
      <div class="form-group">
        <label class="col-md-4 control-label" for="checkboxes"></label>
        <div class="col-md-4">
          <div class="checkbox">
            <label for="checkboxes-0">
              <input id="checkboxes-0" name="checkboxes" type="checkbox" value="1"></input>
              Start a new merge request with these changes
            </label>
          </div>
        </div>
      </div>
      <div class="col-md-offset-4 col-md-4">
        <button type="submit" :disabled="!commitMessage" class="btn btn-success" @click.prevent="makeCommit">Commit {{changedFiles.length}} Files</button>
      </div>
    </fieldset>
  </form>
</div>
</template>