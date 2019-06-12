<script>
import { mapGetters } from 'vuex';

export default {
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
    <slot></slot>
  </div>
</template>
