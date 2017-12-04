<script>
import { mapState } from 'vuex';
import Icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  computed: {
    ...mapState([
      'selectedFile',
    ]),
  },
};
</script>

<template>
  <div
    class="ide-status-bar">
    <div 
      class="col-sm-3">
      <icon
        name="branch"
        :size="12">
      </icon>
      {{ selectedFile.branch }}
    </div>
    <div 
      class="col-sm-3">
      <div
        v-if="selectedFile.lastCommit && selectedFile.lastCommit.message">
        Last commit: {{ selectedFile.lastCommit.message }}
      </div>      
    </div>
    <div 
      class="col-sm-1 col-sm-offset-3 text-right">
      {{ selectedFile.name }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ selectedFile.editorRow }}:{{ selectedFile.editorColumn }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ selectedFile.fileLanguage }}
    </div>
  </div>
</template>
