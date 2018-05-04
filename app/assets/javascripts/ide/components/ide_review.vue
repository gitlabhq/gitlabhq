<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import IdeTreeList from './ide_tree_list.vue';
import EditorModeDropdown from './editor_mode_dropdown.vue';
import { viewerTypes } from '../constants';

export default {
  components: {
    IdeTreeList,
    EditorModeDropdown,
  },
  computed: {
    ...mapGetters(['currentMergeRequest']),
    ...mapState(['viewer']),
    showLatestChangesText() {
      return !this.currentMergeRequest || this.viewer === viewerTypes.diff;
    },
    showMergeRequestText() {
      return this.currentMergeRequest && this.viewer === viewerTypes.mr;
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.updateViewer(this.currentMergeRequest ? viewerTypes.mr : viewerTypes.diff);
    });
  },
  methods: {
    ...mapActions(['updateViewer']),
  },
};
</script>

<template>
  <ide-tree-list
    :viewer-type="viewer"
    header-class="ide-review-header"
    :disable-action-dropdown="true"
  >
    <template
      slot="header"
    >
      <div class="ide-review-button-holder">
        {{ __('Review') }}
        <editor-mode-dropdown
          v-if="currentMergeRequest"
          :viewer="viewer"
          :merge-request-id="currentMergeRequest.iid"
          @click="updateViewer"
        />
      </div>
      <div class="prepend-top-5 ide-review-sub-header">
        <template v-if="showLatestChangesText">
          {{ __('Latest changes') }}
        </template>
        <template v-else-if="showMergeRequestText">
          {{ __('Merge request') }}
          (<a :href="currentMergeRequest.web_url">!{{ currentMergeRequest.iid }}</a>)
        </template>
      </div>
    </template>
  </ide-tree-list>
</template>
