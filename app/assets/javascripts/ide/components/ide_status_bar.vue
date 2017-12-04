<script>
import { mapState } from 'vuex';
import Icon from '../../vue_shared/components/icon.vue';
import tooltip from '../../vue_shared/directives/tooltip';
import timeAgoMixin from '../../vue_shared/mixins/timeago';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  mixins: [
    timeAgoMixin,
  ],
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
      {{ selectedFile.branchId }}
    </div>
    <div 
      class="col-sm-4">
      <div
        v-tooltip
        :title="selectedFile.lastCommit.message"
        v-if="selectedFile.lastCommit && selectedFile.lastCommit.id">
        Last commit:
        <a
          :href="selectedFile.lastCommit.url">
          {{ timeFormated(selectedFile.lastCommit.updatedAt) }} by 
          {{ selectedFile.lastCommit.author }}
        </a>
      </div>      
    </div>
    <div 
      class="col-sm-1 col-sm-offset-2 text-right">
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
