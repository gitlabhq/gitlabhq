<script>
import { mapState } from 'vuex';
import icon from '../../vue_shared/components/icon.vue';
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
    icon,
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
    <div>
      <icon
        name="branch"
        :size="12">
      </icon>
      {{ selectedFile.branchId }}
    </div>
    <div>
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
      class="text-right">
      {{ selectedFile.name }}
    </div>
    <div 
      class="text-right">
      {{ selectedFile.eol }}
    </div>
    <div 
      class="text-right">
      {{ file.editorRow }}:{{ file.editorColumn }}
    </div>
    <div 
      class="text-right">
      {{ selectedFile.fileLanguage }}
    </div>
  </div>
</template>
