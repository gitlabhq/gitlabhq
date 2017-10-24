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
import Service from '../services/repo_service';
import MonacoLoaderHelper from '../helpers/monaco_loader_helper';
import eventHub from '../event_hub';

export default {
  data() {
    return Store;
  },
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
  created() {
    eventHub.$on('createNewBranch', this.createNewBranch);
  },
  mounted() {
    Helper.getContent().catch(Helper.loadingError);
  },
  destroyed() {
    eventHub.$off('createNewBranch', this.createNewBranch);
  },
  methods: {
    getCurrentLocation() {
      return location.href;
    },
    toggleDialogOpen(toggle) {
      this.dialog.open = toggle;
    },

    dialogSubmitted(status) {
      this.toggleDialogOpen(false);
      this.dialog.status = status;
    },
    toggleBlobView: Store.toggleBlobView,
    createNewBranch(branch) {
      Service.createBranch({
        branch,
        ref: Store.currentBranch,
      }).then((res) => {
        const newBranchName = res.data.name;
        const newUrl = this.getCurrentLocation().replace(Store.currentBranch, newBranchName);

        Store.currentBranch = newBranchName;

        history.pushState({ key: Helper.key }, '', newUrl);

        eventHub.$emit('createNewBranchSuccess', newBranchName);
        eventHub.$emit('toggleNewBranchDropdown');
      }).catch((err) => {
        eventHub.$emit('createNewBranchError', err.response.data.message);
      });
    },
  },
};
</script>

<template>
  <div class="repository-view">
    <div class="tree-content-holder" :class="{'tree-content-holder-mini' : isMini}">
      <repo-sidebar/>
      <div v-if="isMini"
      class="panel-right"
      :class="{'edit-mode': editMode}">
        <repo-tabs/>
        <component
          :is="currentBlobView"
          class="blob-viewer-container"/>
        <repo-file-buttons/>
      </div>
    </div>
    <repo-commit-section/>
    <popup-dialog
      v-show="dialog.open"
      :primary-button-label="__('Discard changes')"
      kind="warning"
      :title="__('Are you sure?')"
      :text="__('Are you sure you want to discard your changes?')"
      @toggle="toggleDialogOpen"
      @submit="dialogSubmitted"
    />
  </div>
</template>
