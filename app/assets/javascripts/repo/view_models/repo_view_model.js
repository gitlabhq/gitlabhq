import Vue from 'vue';
import RepoSidebar from '../components/repo_sidebar.vue';
import RepoCommitSection from '../components/repo_commit_section.vue';
import RepoTabs from '../components/repo_tabs.vue';
import RepoFileButtons from '../components/repo_file_buttons.vue';
import RepoBinaryViewer from '../components/repo_binary_viewer.vue';
import RepoMixin from '../mixins/repo_mixin';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';
import Store from '../stores/repo_store';
import MonacoLoaderHelper from '../helpers/monaco_loader_helper';

const Repo = {
  el: undefined,
  data: () => Store,
  template: `
    <div class="tree-content-holder">
      <repo-sidebar/><div class="panel-right" :class="{'edit-mode': editMode}">
        <repo-tabs/>
        <repo-file-buttons/>
        <repo-editor/>
        <repo-binary-viewer/>
      </div>
      <repo-commit-section/>
      <popup-dialog
        :primary-button-label="__('Discard changes')"
        :open="dialog.open"
        kind="warning"
        :title="__('Are you sure?')"
        :body="__('Are you sure you want to discard your changes?')"
        @toggle="dialogToggled"
        @submit="dialogSubmitted"
      />
    </div>
  `,
  mixins: [RepoMixin],
  components: {
    'repo-sidebar': RepoSidebar,
    'repo-tabs': RepoTabs,
    'repo-file-buttons': RepoFileButtons,
    'repo-binary-viewer': RepoBinaryViewer,
    'repo-editor': MonacoLoaderHelper.repoEditorLoader,
    'repo-commit-section': RepoCommitSection,
    'popup-dialog': PopupDialog,
  },

  methods: {
    dialogToggled(toggle) {
      this.dialog.open = toggle;
    },

    dialogSubmitted(status) {
      this.dialog.open = false;
      this.dialog.status = status;
    },
  },
};

function initRepoViewModel(el) {
  Repo.el = el;

  return new Vue(Repo);
}

export {
  Repo as default,
  initRepoViewModel,
};
