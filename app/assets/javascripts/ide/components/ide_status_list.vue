<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { isTextFile, getFileEOL } from '~/ide/utils';
import TerminalSyncStatusSafe from './terminal_sync/terminal_sync_status_safe.vue';

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
    ...mapGetters('editor', ['activeFileEditor']),
    activeFileEOL() {
      return getFileEOL(this.activeFile.content);
    },
    activeFileIsText() {
      return isTextFile(this.activeFile);
    },
  },
};
</script>

<template>
  <div class="ide-status-list gl-flex">
    <template v-if="activeFile">
      <div>
        <gl-link v-gl-tooltip.hover :href="activeFile.permalink" :title="__('Open in file view')">
          {{ activeFile.name }}
        </gl-link>
      </div>
      <div>{{ activeFileEOL }}</div>
      <div v-if="activeFileIsText">
        {{ activeFileEditor.editorRow }}:{{ activeFileEditor.editorColumn }}
      </div>
      <div>{{ activeFileEditor.fileLanguage }}</div>
    </template>
    <terminal-sync-status-safe />
  </div>
</template>
