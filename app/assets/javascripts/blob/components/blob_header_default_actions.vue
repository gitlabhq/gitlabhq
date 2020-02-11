<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER,
} from './constants';
import eventHub from '../event_hub';

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
    activeViewer: {
      type: String,
      default: SIMPLE_BLOB_VIEWER,
      required: false,
    },
  },
  computed: {
    rawUrl() {
      return this.blob.rawPath;
    },
    downloadUrl() {
      return `${this.blob.rawPath}?inline=false`;
    },
    copyDisabled() {
      return this.activeViewer === RICH_BLOB_VIEWER;
    },
  },
  methods: {
    requestCopyContents() {
      eventHub.$emit('copy');
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
      :disabled="copyDisabled"
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
