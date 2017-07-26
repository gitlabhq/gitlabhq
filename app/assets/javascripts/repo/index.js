/* global monaco */
import $ from 'jquery';
import Vue from 'vue';
import RepoSidebar from './repo_sidebar.vue';
import EditButton from './repo_edit_button';
import Service from './repo_service';
import Store from './repo_store';
import RepoCommitSection from './repo_commit_section.vue';
import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoBinaryViewer from './repo_binary_viewer.vue';
import RepoEditor from './repo_editor';
import RepoMiniMixin from './repo_mini_mixin';

function initRepo() {
  const repo = document.getElementById('repo');

  Store.service = Service;
  Store.service.url = repo.dataset.url;
  Store.projectName = repo.dataset.projectName;
  Store.service.refsUrl = repo.dataset.refsUrl;
  Store.currentBranch = $('button.dropdown-menu-toggle').attr('data-ref');
  Store.checkIsCommitable();
  Store.projectId = repo.dataset.projectId;
  Store.tempPrivateToken = repo.dataset.tempToken;

  this.vm = new Vue({
    el: repo,
    data: () => Store,
    template: `
      <div class="tree-content-holder">
        <repo-sidebar/><div class="panel-right" :class="{'edit-mode': readOnly}">
          <repo-tabs/>
          <repo-file-buttons/>
          <repo-editor/>
          <repo-binary-viewer/>
        </div>
        <repo-commit-section/>
      </div>
    `,
    mixins: [RepoMiniMixin],
    components: {
      'repo-sidebar': RepoSidebar,
      'repo-tabs': RepoTabs,
      'repo-file-buttons': RepoFileButtons,
      'repo-binary-viewer': RepoBinaryViewer,
      'repo-editor': RepoEditor,
      'repo-commit-section': RepoCommitSection,
    },
  });

  const editButton = document.getElementById('editable-mode');
  Store.editButton = new EditButton(editButton);
}

$(initRepo);

export default initRepo;
