<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import IdeTreeList from './ide_tree_list.vue';
import Upload from './new_dropdown/upload.vue';
import NewEntryButton from './new_dropdown/button.vue';

export default {
  components: {
    Icon,
    Upload,
    IdeTreeList,
    NewEntryButton,
  },
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'currentTree', 'activeFile']),
  },
  mounted() {
    if (this.activeFile && this.activeFile.pending) {
      this.$router.push(`/project${this.activeFile.url}`, () => {
        this.updateViewer('editor');
      });
    }
  },
  methods: {
    ...mapActions(['updateViewer', 'openNewEntryModal', 'createTempEntry']),
  },
};
</script>

<template>
  <ide-tree-list
    header-class="d-flex w-100"
    viewer-type="editor"
  >
    <template
      slot="header"
    >
      {{ __('Edit') }}
      <div class="ml-auto d-flex">
        <new-entry-button
          :label="__('New file')"
          :show-label="false"
          class="d-flex border-0 p-0 mr-3"
          icon="doc-new"
          @click="openNewEntryModal({ type: 'blob' })"
        />
        <upload
          :show-label="false"
          class="d-flex mr-3"
          button-css-classes="border-0 p-0"
          @create="createTempEntry"
        />
        <new-entry-button
          :label="__('New directory')"
          :show-label="false"
          class="d-flex border-0 p-0"
          icon="folder-new"
          @click="openNewEntryModal({ type: 'tree' })"
        />
      </div>
    </template>
  </ide-tree-list>
</template>
