<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  name: 'PipelineEditorFileItem',
  components: {
    FileIcon,
    GlIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fileName() {
      return this.file.location;
    },
    filePath() {
      return this.file.blob || this.file.raw;
    },
  },
};
</script>
<template>
  <gl-link
    v-gl-tooltip
    :href="filePath"
    :title="fileName"
    target="_blank"
    class="file-tree-includes-link gl-display-flex gl-justify-content-space-between gl-hover-bg-gray-50 gl-text-body gl-hover-text-gray-900 gl-hover-text-decoration-none gl-py-2 gl-px-3 gl-rounded-base"
  >
    <span class="file-row-name gl-str-truncated" :title="fileName">
      <file-icon class="file-row-icon" :file-name="fileName" />
      <span>{{ fileName }}</span>
    </span>
    <gl-icon class="gl-hidden gl-relative gl-text-gray-500" name="external-link" />
  </gl-link>
</template>
