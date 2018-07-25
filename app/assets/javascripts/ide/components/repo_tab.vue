<script>
import { mapActions } from 'vuex';

import FileIcon from '~/vue_shared/components/file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
import FileStatusIcon from './repo_file_status_icon.vue';
import ChangedFileIcon from './changed_file_icon.vue';

export default {
  components: {
    FileStatusIcon,
    FileIcon,
    Icon,
    ChangedFileIcon,
  },
  props: {
    tab: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      tabMouseOver: false,
    };
  },
  computed: {
    closeLabel() {
      if (this.fileHasChanged) {
        return `${this.tab.name} changed`;
      }
      return `Close ${this.tab.name}`;
    },
    showChangedIcon() {
      if (this.tab.pending) return true;

      return this.fileHasChanged ? !this.tabMouseOver : false;
    },
    fileHasChanged() {
      return this.tab.changed || this.tab.tempFile || this.tab.staged;
    },
  },

  methods: {
    ...mapActions(['closeFile', 'updateDelayViewerUpdated', 'openPendingTab']),
    clickFile(tab) {
      if (tab.active) return;

      this.updateDelayViewerUpdated(true);

      if (tab.pending) {
        this.openPendingTab({ file: tab, keyPrefix: tab.staged ? 'staged' : 'unstaged' });
      } else {
        this.$router.push(`/project${tab.url}`);
      }
    },
    mouseOverTab() {
      if (this.fileHasChanged) {
        this.tabMouseOver = true;
      }
    },
    mouseOutTab() {
      if (this.fileHasChanged) {
        this.tabMouseOver = false;
      }
    },
  },
};
</script>

<template>
  <li
    :class="{
      active: tab.active
    }"
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <div
      :title="tab.url"
      class="multi-file-tab"
    >
      <file-icon
        :file-name="tab.name"
        :size="16"
      />
      {{ tab.name }}
      <file-status-icon
        :file="tab"
      />
    </div>
    <button
      :aria-label="closeLabel"
      :disabled="tab.pending"
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile(tab)"
    >
      <icon
        v-if="!showChangedIcon"
        :size="12"
        name="close"
      />
      <changed-file-icon
        v-else
        :file="tab"
        :force-modified-icon="true"
      />
    </button>
  </li>
</template>
