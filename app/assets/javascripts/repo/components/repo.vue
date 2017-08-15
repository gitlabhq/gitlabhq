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
    RepoSidebar,
    RepoTabs,
    RepoFileButtons,
    'repo-editor': MonacoLoaderHelper.repoEditorLoader,
    RepoCommitSection,
    PopupDialog,
    RepoPreview,
  },

  mounted() {
    Helper.getContent().catch(Helper.loadingError);
  },

  methods: {
    toggleDialogOpen(toggle) {
      this.dialog.open = toggle;
    },

    dialogSubmitted(status) {
      this.toggleDialogOpen(false);
      this.dialog.status = status;
    },

    toggleBlobView: Store.toggleBlobView,
  },
};
</script>

<template>
  <div class="repository-view tree-content-holder">
    <repo-sidebar/><div v-if="isMini"
    class="panel-right"
    :class="{'edit-mode': editMode}">
      <repo-tabs/>
      <component
        :is="currentBlobView"
        class="blob-viewer-container"/>
      <repo-file-buttons/>
    </div>
    <repo-commit-section/>
    <popup-dialog
      v-show="dialog.open"
      :primary-button-label="__('Discard changes')"
      kind="warning"
      :title="__('Are you sure?')"
      :body="__('Are you sure you want to discard your changes?')"
      @toggle="toggleDialogOpen"
      @submit="dialogSubmitted"
    />
  </div>
</template>
