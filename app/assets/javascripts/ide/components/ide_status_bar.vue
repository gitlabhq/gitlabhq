<script>
import { mapGetters } from 'vuex';
import Icon from '../../vue_shared/components/icon.vue'

export default {
  components: {
    Icon,
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'activeFileEditorPosition',
    ]),
  }
};
</script>

<template>
  <div
    class="ide-status-bar row">
    <div 
      class="col-sm-2">
      <icon
        name="branch"
        :size="12">
      </icon>
      master
    </div>
    <div 
      class="col-sm-2">
      Latest commit: 123
    </div>
    <div 
      class="col-sm-1 col-sm-offset-4 text-right">
      {{ activeFile.name }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ activeFileEditorPosition }}
      {{ activeFile.editorRow }}:{{ activeFile.editorColumn }}
    </div>
    <div 
      class="col-sm-1 text-right">
      
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ activeFile.fileLanguage }}
    </div>
  </div>
</template>
