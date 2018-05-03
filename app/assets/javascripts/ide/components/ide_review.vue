<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import IdeTreeList from './ide_tree_list.vue';
import EditorModeDropdown from './editor_mode_dropdown.vue';

export default {
  components: {
    IdeTreeList,
    EditorModeDropdown,
  },
  computed: {
    ...mapGetters(['currentMergeRequest']),
    ...mapState(['viewer']),
  },
  mounted() {
    this.updateViewer(this.currentMergeRequest ? 'mrdiff' : 'diff');
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
        <template v-if="!currentMergeRequest || viewer === 'diff'">
          {{ __('Lastest changes') }}
        </template>
        <template v-else-if="currentMergeRequest && viewer === 'mrdiff'">
          Merge request
          (<a :href="currentMergeRequest.web_url">!{{ currentMergeRequest.iid }}</a>)
        </template>
      </div>
    </template>
  </ide-tree-list>
</template>

<style>
.ide-review-button-holder {
  display: flex;
  width: 100%;
  align-items: center;
}
</style>
