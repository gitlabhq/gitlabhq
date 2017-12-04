<script>
import { mapState } from 'vuex';
import Icon from '../../vue_shared/components/icon.vue';
import tooltip from '../../vue_shared/directives/tooltip';
import timeAgoMixin from '../../vue_shared/mixins/timeago';

export default {
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
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
        v-if="selectedFile.lastCommit && selectedFile.lastCommit.id">
        Last commit:
        <a
          v-tooltip
          :title="selectedFile.lastCommit.message"
          :href="selectedFile.lastCommit.url">
          {{ timeFormated(selectedFile.lastCommit.updatedAt) }} by 
          {{ selectedFile.lastCommit.author }}
        </a>
      </div>      
    </div>
    <div 
      class="col-sm-1 col-sm-offset-1 text-right">
      {{ selectedFile.name }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ selectedFile.EOL }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ file.editorRow }}:{{ file.editorColumn }}
    </div>
    <div 
      class="col-sm-1 text-right">
      {{ selectedFile.fileLanguage }}
    </div>
  </div>
</template>
