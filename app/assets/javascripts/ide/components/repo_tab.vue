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
      if (this.tab.changed || this.tab.tempFile) {
        return `${this.tab.name} changed`;
      }
      return `Close ${this.tab.name}`;
    },
    showChangedIcon() {
      return this.tab.changed ? !this.tabMouseOver : false;
    },
  },

  methods: {
    ...mapActions(['closeFile', 'updateDelayViewerUpdated', 'openPendingTab']),
    clickFile(tab) {
      this.updateDelayViewerUpdated(true);

      if (tab.pending) {
        this.openPendingTab(tab);
      } else {
        this.$router.push(`/project${tab.url}`);
      }
    },
    mouseOverTab() {
      if (this.tab.changed) {
        this.tabMouseOver = true;
      }
    },
    mouseOutTab() {
      if (this.tab.changed) {
        this.tabMouseOver = false;
      }
    },
  },
};
</script>

<template>
  <li
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile(tab)"
      :aria-label="closeLabel"
    >
      <icon
        v-if="!showChangedIcon"
        name="close"
        :size="12"
      />
      <changed-file-icon
        v-else
        :file="tab"
      />
    </button>

    <div
      class="multi-file-tab"
      :class="{
        active: tab.active
      }"
      :title="tab.url"
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
  </li>
</template>
