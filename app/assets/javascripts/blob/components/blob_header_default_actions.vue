<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { BTN_COPY_CONTENTS_TITLE, BTN_DOWNLOAD_TITLE, BTN_RAW_TITLE } from './constants';

export default {
  components: {
    GlIcon,
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  computed: {
    rawUrl() {
      return this.blob.rawPath;
    },
    downloadUrl() {
      return `${this.blob.rawPath}?inline=false`;
    },
  },
  methods: {
    requestCopyContents() {
      this.$emit('copy');
    },
  },
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
};
</script>
<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.BTN_COPY_CONTENTS_TITLE"
      :title="$options.BTN_COPY_CONTENTS_TITLE"
      @click="requestCopyContents"
    >
      <gl-icon name="copy-to-clipboard" :size="14" />
    </gl-button>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.BTN_RAW_TITLE"
      :title="$options.BTN_RAW_TITLE"
      :href="rawUrl"
      target="_blank"
    >
      <gl-icon name="doc-code" :size="14" />
    </gl-button>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.BTN_DOWNLOAD_TITLE"
      :title="$options.BTN_DOWNLOAD_TITLE"
      :href="downloadUrl"
      target="_blank"
    >
      <gl-icon name="download" :size="14" />
    </gl-button>
  </gl-button-group>
</template>
