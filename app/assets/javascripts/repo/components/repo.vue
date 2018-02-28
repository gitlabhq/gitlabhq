<script>
import { mapState, mapGetters } from 'vuex';
import RepoSidebar from './repo_sidebar.vue';
import RepoCommitSection from './repo_commit_section.vue';
import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoPreview from './repo_preview.vue';
import repoEditor from './repo_editor.vue';

export default {
  computed: {
    ...mapState([
      'currentBlobView',
    ]),
    ...mapGetters([
      'isCollapsed',
      'changedFiles',
    ]),
  },
  components: {
    RepoSidebar,
    RepoTabs,
    RepoFileButtons,
    repoEditor,
    RepoCommitSection,
    RepoPreview,
  },
  mounted() {
    const returnValue = 'Are you sure you want to lose unsaved changes?';
    window.onbeforeunload = (e) => {
      if (!this.changedFiles.length) return undefined;

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    };
  },
};
</script>

<template>
  <div
    class="multi-file"
    :class="{
      'is-collapsed': isCollapsed
    }"
  >
    <repo-sidebar/>
    <div
      v-if="isCollapsed"
      class="multi-file-edit-pane"
    >
      <repo-tabs />
      <component
        class="multi-file-edit-pane-content"
        :is="currentBlobView"
      />
      <repo-file-buttons />
    </div>
    <repo-commit-section />
  </div>
</template>
