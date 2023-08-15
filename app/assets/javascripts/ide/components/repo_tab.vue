<script>
import { GlIcon, GlTab } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { __, sprintf } from '~/locale';

import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileStatusIcon from './repo_file_status_icon.vue';

export default {
  components: {
    FileStatusIcon,
    FileIcon,
    GlIcon,
    ChangedFileIcon,
    GlTab,
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
    ...mapGetters(['getUrlForPath']),
    closeLabel() {
      if (this.fileHasChanged) {
        return sprintf(__('%{tabname} changed'), { tabname: this.tab.name });
      }
      return sprintf(__('Close %{tabname}'), { tabname: this.tab.name });
    },
    showChangedIcon() {
      if (this.tab.pending) return true;

      return this.fileHasChanged ? !this.tabMouseOver : false;
    },
    fileHasChanged() {
      return this.tab.changed || this.tab.tempFile || this.tab.staged || this.tab.deleted;
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
        this.$router.push(this.getUrlForPath(tab.path));
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
  <gl-tab
    :active="tab.active"
    :disabled="tab.pending"
    :title="tab.name"
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <template #title>
      <div :title="getUrlForPath(tab.path)" class="multi-file-tab">
        <file-icon :file-name="tab.name" :size="16" />
        {{ tab.name }}
        <file-status-icon :file="tab" />
      </div>
      <button
        :aria-label="closeLabel"
        :disabled="tab.pending"
        type="button"
        class="multi-file-tab-close"
        data-testid="close-button"
        @click.stop.prevent="closeFile(tab)"
      >
        <gl-icon v-if="!showChangedIcon" :size="12" name="close" />
        <changed-file-icon v-else :file="tab" />
      </button>
    </template>
  </gl-tab>
</template>
