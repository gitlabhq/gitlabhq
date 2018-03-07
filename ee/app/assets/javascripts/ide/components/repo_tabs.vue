<script>
  import { mapActions, mapGetters, mapState } from 'vuex';
  import RepoTab from './repo_tab.vue';
  import EditorMode from './editor_mode_dropdown.vue';

  export default {
    components: {
      RepoTab,
      EditorMode,
    },
    data() {
      return {
        showShadow: false,
      };
    },
    computed: {
      ...mapGetters([
        'hasChanges',
      ]),
      ...mapState([
        'openFiles',
        'viewer',
      ]),
    },
    updated() {
      if (!this.$refs.tabsScroller) return;

      this.showShadow = this.$refs.tabsScroller.scrollWidth > this.$refs.tabsScroller.offsetWidth;
    },
    methods: {
      ...mapActions([
        'updateViewer',
      ]),
    },
  };
</script>

<template>
  <div class="multi-file-tabs">
    <ul
      class="list-unstyled append-bottom-0"
      ref="tabsScroller"
    >
      <repo-tab
        v-for="tab in openFiles"
        :key="tab.key"
        :tab="tab"
      />
    </ul>
    <editor-mode
      :viewer="viewer"
      :show-shadow="showShadow"
      :has-changes="hasChanges"
      @click="updateViewer"
    />
  </div>
</template>
