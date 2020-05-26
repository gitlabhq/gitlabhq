<script>
import { GlDeprecatedButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER,
} from './constants';

export default {
  components: {
    GlIcon,
    GlButtonGroup,
    GlDeprecatedButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    rawPath: {
      type: String,
      required: true,
    },
    activeViewer: {
      type: String,
      default: SIMPLE_BLOB_VIEWER,
      required: false,
    },
    hasRenderError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    downloadUrl() {
      return `${this.rawPath}?inline=false`;
    },
    copyDisabled() {
      return this.activeViewer === RICH_BLOB_VIEWER;
    },
  },
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
};
</script>
<template>
  <gl-button-group>
    <gl-deprecated-button
      v-if="!hasRenderError"
      v-gl-tooltip.hover
      :aria-label="$options.BTN_COPY_CONTENTS_TITLE"
      :title="$options.BTN_COPY_CONTENTS_TITLE"
      :disabled="copyDisabled"
      data-clipboard-target="#blob-code-content"
      data-testid="copyContentsButton"
    >
      <gl-icon name="copy-to-clipboard" :size="14" />
    </gl-deprecated-button>
    <gl-deprecated-button
      v-gl-tooltip.hover
      :aria-label="$options.BTN_RAW_TITLE"
      :title="$options.BTN_RAW_TITLE"
      :href="rawPath"
      target="_blank"
    >
      <gl-icon name="doc-code" :size="14" />
    </gl-deprecated-button>
    <gl-deprecated-button
      v-gl-tooltip.hover
      :aria-label="$options.BTN_DOWNLOAD_TITLE"
      :title="$options.BTN_DOWNLOAD_TITLE"
      :href="downloadUrl"
      target="_blank"
    >
      <gl-icon name="download" :size="14" />
    </gl-deprecated-button>
  </gl-button-group>
</template>
