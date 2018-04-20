<script>
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeAgoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    icon,
  },
  directives: {
    tooltip,
  },
  mixins: [timeAgoMixin],
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="ide-status-bar">
    <div>
      <div v-if="file.lastCommit && file.lastCommit.id">
        Last commit:
        <a
          v-tooltip
          :title="file.lastCommit.message"
          :href="file.lastCommit.url"
        >
          {{ timeFormated(file.lastCommit.updatedAt) }} by
          {{ file.lastCommit.author }}
        </a>
      </div>
    </div>
    <div class="text-right">
      {{ file.name }}
    </div>
    <div class="text-right">
      {{ file.eol }}
    </div>
    <div
      class="text-right"
      v-if="!file.binary">
      {{ file.editorRow }}:{{ file.editorColumn }}
    </div>
    <div class="text-right">
      {{ file.fileLanguage }}
    </div>
  </div>
</template>
