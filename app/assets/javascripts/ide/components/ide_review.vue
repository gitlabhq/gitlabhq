<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState, mapActions } from 'vuex';
import { viewerTypes } from '../constants';
import EditorModeDropdown from './editor_mode_dropdown.vue';
import IdeTreeList from './ide_tree_list.vue';

export default {
  components: {
    IdeTreeList,
    EditorModeDropdown,
  },
  computed: {
    ...mapGetters(['currentMergeRequest', 'activeFile', 'getUrlForPath']),
    ...mapState(['viewer', 'currentMergeRequestId']),
    showLatestChangesText() {
      return !this.currentMergeRequestId || this.viewer === viewerTypes.diff;
    },
    showMergeRequestText() {
      return this.currentMergeRequestId && this.viewer === viewerTypes.mr;
    },
    mergeRequestId() {
      return `!${this.currentMergeRequest.iid}`;
    },
  },
  mounted() {
    this.initialize();
  },
  activated() {
    this.initialize();
  },
  methods: {
    ...mapActions(['updateViewer', 'resetOpenFiles']),
    initialize() {
      if (this.activeFile && this.activeFile.pending && !this.activeFile.deleted) {
        this.$router.push(this.getUrlForPath(this.activeFile.path), () => {
          this.updateViewer(viewerTypes.edit);
        });
      } else if (this.activeFile && this.activeFile.deleted) {
        this.resetOpenFiles();
      }

      this.$nextTick(() => {
        this.updateViewer(this.currentMergeRequestId ? viewerTypes.mr : viewerTypes.diff);
      });
    },
  },
};
</script>

<template>
  <ide-tree-list header-class="ide-review-header">
    <template #header>
      <div class="ide-review-button-holder">
        {{ __('Review') }}
        <editor-mode-dropdown
          v-if="currentMergeRequest"
          :viewer="viewer"
          :merge-request-id="currentMergeRequest.iid"
          @click="updateViewer"
        />
      </div>
      <div class="ide-review-sub-header gl-mt-2">
        <template v-if="showLatestChangesText">
          {{ __('Latest changes') }}
        </template>
        <template v-else-if="showMergeRequestText">
          {{ __('Merge request') }} (<a
            v-if="currentMergeRequest"
            :href="currentMergeRequest.web_url"
            v-text="mergeRequestId"
          ></a
          >)
        </template>
      </div>
    </template>
  </ide-tree-list>
</template>
