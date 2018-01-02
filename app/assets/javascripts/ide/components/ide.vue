<script>
import { mapState, mapGetters } from 'vuex';
import ideSidebar from './ide_side_bar.vue';
import ideContextbar from './ide_context_bar.vue';
import repoTabs from './repo_tabs.vue';
import repoFileButtons from './repo_file_buttons.vue';
import ideStatusBar from './ide_status_bar.vue';
import repoPreview from './repo_preview.vue';
import repoEditor from './repo_editor.vue';

export default {
  computed: {
    ...mapState([
      'currentBlobView',
      'selectedFile',
    ]),
    ...mapGetters([
      'changedFiles',
      'activeFile',
    ]),
  },
  components: {
    ideSidebar,
    ideContextbar,
    repoTabs,
    repoFileButtons,
    ideStatusBar,
    repoEditor,
    repoPreview,
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
    class="ide-view"
  >
    <ide-sidebar/>
    <div
      class="multi-file-edit-pane"
    >
      <template
        v-if="activeFile">
        <repo-tabs/>
        <component
          class="multi-file-edit-pane-content"
          :is="currentBlobView"
        />
        <repo-file-buttons/>
        <ide-status-bar
          :file="selectedFile"/>
      </template>
      <template
        v-else>
        <div class="ide-empty-state">
          <h2 class="clgray">Welcome to the GitLab IDE</h2>
        </div>
      </template>
    </div>
    <ide-contextbar/>
  </div>
</template>
