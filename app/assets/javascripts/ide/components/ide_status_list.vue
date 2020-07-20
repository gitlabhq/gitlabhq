<script>
import { mapGetters } from 'vuex';
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import TerminalSyncStatusSafe from './terminal_sync/terminal_sync_status_safe.vue';
import { getFileEOL } from '../utils';

export default {
  components: {
    GlLink,
    TerminalSyncStatusSafe,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapGetters(['activeFile']),
    activeFileEOL() {
      return getFileEOL(this.activeFile.content);
    },
  },
};
</script>

<template>
  <div class="ide-status-list d-flex">
    <template v-if="activeFile">
      <div>
        <gl-link v-gl-tooltip.hover :href="activeFile.permalink" :title="__('Open in file view')">
          {{ activeFile.name }}
        </gl-link>
      </div>
      <div>{{ activeFileEOL }}</div>
      <div v-if="!activeFile.binary">{{ activeFile.editorRow }}:{{ activeFile.editorColumn }}</div>
      <div>{{ activeFile.fileLanguage }}</div>
    </template>
    <terminal-sync-status-safe />
  </div>
</template>
