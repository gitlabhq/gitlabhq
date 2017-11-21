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
  <div class="ide-view page-gutter page-with-contextual-sidebar page-with-sidebar right-sidebar-collapsed">
    <ide-sidebar/>
    <div class="content-wrapper page-with-new-nav">
      <div class="container-fluid container-limited limit-container-width">
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
            EMPTY
          </template>
        </div>
      </div>
    </div>
  </div>
    
</template>
