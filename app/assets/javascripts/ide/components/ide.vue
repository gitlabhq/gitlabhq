<script>
import { mapState, mapGetters } from 'vuex';
import IdeSidebar from './ide_side_bar.vue';
import IdeContextbar from './ide_context_bar.vue';

import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoPreview from './repo_preview.vue';
import RepoEditor from './repo_editor.vue';

export default {
  computed: {
    ...mapState([
      'currentBlobView',
    ]),
    ...mapGetters([
      'isCollapsed',
      'changedFiles',
      'activeFile',
    ]),
  },
  components: {
    IdeSidebar,
    IdeContextbar,
    RepoTabs,
    RepoFileButtons,
    RepoEditor,
    RepoPreview,
  },
  mounted() {
    /* const returnValue = 'Are you sure you want to lose unsaved changes?';
    window.onbeforeunload = (e) => {
      if (!this.changedFiles.length) return undefined;

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    }; */
  },
};
</script>

<template>
  <div class="ide-view page-gutter page-with-contextual-sidebar page-with-sidebar right-sidebar-collapsed">
    <ide-sidebar/>
    <div class="panel-right content-wrapper page-with-new-nav">
      <div class="content" id="content-body">
        <ide-contextbar/>
        <template
          v-if="activeFile">
          <repo-tabs/>
          <component
            :is="currentBlobView"
          />
          <repo-file-buttons/>
        </template>
        <template
          v-else>
          <br/><br/><br/><br/><br/>
          <h4 class="muted text-center">Welcome to the GitLab IDE</h4>
        </template>
      </div>
    </div>
  </div>
    
</template>
