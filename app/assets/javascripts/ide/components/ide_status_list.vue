<script>
import { mapGetters } from 'vuex';
import TerminalSyncStatusSafe from './terminal_sync/terminal_sync_status_safe.vue';

export default {
  components: {
    TerminalSyncStatusSafe,
  },
  computed: {
    ...mapGetters(['activeFile']),
  },
};
</script>

<template>
  <div class="ide-status-list d-flex">
    <template v-if="activeFile">
      <div class="ide-status-file">{{ activeFile.name }}</div>
      <div class="ide-status-file">{{ activeFile.eol }}</div>
      <div v-if="!activeFile.binary" class="ide-status-file">
        {{ activeFile.editorRow }}:{{ activeFile.editorColumn }}
      </div>
      <div class="ide-status-file">{{ activeFile.fileLanguage }}</div>
    </template>
    <terminal-sync-status-safe />
  </div>
</template>
