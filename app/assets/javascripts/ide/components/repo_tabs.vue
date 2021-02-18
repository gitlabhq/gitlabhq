<script>
import { GlTabs } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import RepoTab from './repo_tab.vue';

export default {
  components: {
    RepoTab,
    GlTabs,
  },
  props: {
    activeFile: {
      type: Object,
      required: true,
    },
    files: {
      type: Array,
      required: true,
    },
    viewer: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getUrlForPath']),
  },
  methods: {
    ...mapActions(['updateViewer', 'removePendingTab']),
    openFileViewer(viewer) {
      this.updateViewer(viewer);

      if (this.activeFile.pending) {
        return this.removePendingTab(this.activeFile).then(() => {
          this.$router.push(this.getUrlForPath(this.activeFile.path));
        });
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="multi-file-tabs">
    <gl-tabs>
      <repo-tab v-for="tab in files" :key="tab.key" :tab="tab" />
    </gl-tabs>
  </div>
</template>
