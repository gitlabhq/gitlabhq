<script>
import RepoSidebar from './repo_sidebar.vue';
import RepoCommitSection from './repo_commit_section.vue';
import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoPreview from './repo_preview.vue';
import RepoMixin from '../mixins/repo_mixin';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';
import MonacoLoaderHelper from '../helpers/monaco_loader_helper';

export default {
  data: () => Store,
  mixins: [RepoMixin],
  components: {
    'repo-sidebar': RepoSidebar,
    'repo-tabs': RepoTabs,
    'repo-file-buttons': RepoFileButtons,
    'repo-editor': MonacoLoaderHelper.repoEditorLoader,
    'repo-commit-section': RepoCommitSection,
    'popup-dialog': PopupDialog,
    'repo-preview': RepoPreview,
  },

  mounted() {
    Helper.getContent().catch(Helper.loadingError);
  },

  methods: {
    dialogToggled(toggle) {
      this.dialog.open = toggle;
    },

    dialogSubmitted(status) {
      this.dialog.open = false;
      this.dialog.status = status;
    },

    toggleBlobView: Store.toggleBlobView,
  },
};
</script>

<template>
  <div class="repository-view tree-content-holder">
    <!-- Place both elements side by side to prevent whitespace -->
    <repo-sidebar /><div class="panel-right" :class="{'edit-mode': editMode}">
      <repo-tabs />
      <component :is="currentBlobView" class="blob-viewer-container" />
      <repo-file-buttons />
    </div>
    <repo-commit-section />
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
</template>
