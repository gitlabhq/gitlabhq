/* global monaco */
import $ from 'jquery';
import Vue from 'vue';
import RepoSidebar from './repo_sidebar.vue';
import EditButton from './repo_edit_button';
import CommitSection from './repo_commit_section';
import Service from './repo_service';
import Store from './repo_store';
import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoBinaryViewer from './repo_binary_viewer.vue';
import RepoEditor from './repo_editor.vue';
import RepoMiniMixin from './repo_mini_mixin';

function initRepo() {
  const repo = document.getElementById('repo');

  Store.service = Service;
  Store.service.url = repo.dataset.url;
  Store.projectName = repo.dataset.projectName;

  new Vue({
    el: repo,
    data: () => Store,
    template: `
      <div class="tree-content-holder">
        <repo-sidebar/><div class="panel-right">
          <repo-tabs/>
          <repo-file-buttons/>
          <repo-editor/>
          <repo-binary-viewer/>
        </div>
      </div>
    `,
    mixins: [RepoMiniMixin],
    components: {
      'repo-sidebar': RepoSidebar,
      'repo-tabs': RepoTabs,
      'repo-file-buttons': RepoFileButtons,
      'repo-binary-viewer': RepoBinaryViewer,
      'repo-editor': RepoEditor,
    },
  });

  const editButton = document.getElementById('editable-mode');
  const commitSection = document.getElementById('commit-area');

  Store.editButton = new EditButton(editButton);
  Store.commitSection = new CommitSection(commitSection);
}

$(initRepo);

export default initRepo;
