<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { setUrlParams, relativePathToAbsolute, getBaseURL } from '~/lib/utils/url_utility';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER,
} from './constants';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    blobHash: {
      default: '',
    },
    canDownloadCode: {
      default: true,
    },
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
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
    environmentName: {
      type: String,
      required: false,
      default: null,
    },
    environmentPath: {
      type: String,
      required: false,
      default: null,
    },
    isEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    downloadUrl() {
      return setUrlParams({ inline: false }, relativePathToAbsolute(this.rawPath, getBaseURL()));
    },
    copyDisabled() {
      return this.activeViewer === RICH_BLOB_VIEWER;
    },
    getBlobHashTarget() {
      if (this.overrideCopy) {
        return null;
      }

      return `[data-blob-hash="${this.blobHash}"]`;
    },
    showCopyButton() {
      return !this.hasRenderError && !this.isBinary;
    },
    environmentTitle() {
      return sprintf(s__('BlobViewer|View on %{environmentName}'), {
        environmentName: this.environmentName,
      });
    },
  },
  methods: {
    onCopy() {
      if (this.overrideCopy) {
        this.$emit('copy');
      }
    },
  },
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
};
</script>
<template>
  <gl-button-group data-testid="default-actions-container">
    <gl-button
      v-if="!isEmpty && showCopyButton"
      v-gl-tooltip.hover
      :aria-label="$options.BTN_COPY_CONTENTS_TITLE"
      :title="$options.BTN_COPY_CONTENTS_TITLE"
      :disabled="copyDisabled"
      :data-clipboard-target="getBlobHashTarget"
      data-testid="copy-contents-button"
      icon="copy-to-clipboard"
      category="primary"
      variant="default"
      class="js-copy-blob-source-btn"
      @click="onCopy"
    />
    <gl-button
      v-if="!isEmpty && !isBinary"
      v-gl-tooltip.hover
      :aria-label="$options.BTN_RAW_TITLE"
      :title="$options.BTN_RAW_TITLE"
      :href="rawPath"
      target="_blank"
      icon="doc-code"
      category="primary"
      variant="default"
    />
    <gl-button
      v-if="!isEmpty && canDownloadCode"
      v-gl-tooltip.hover
      :aria-label="$options.BTN_DOWNLOAD_TITLE"
      :title="$options.BTN_DOWNLOAD_TITLE"
      :href="downloadUrl"
      data-testid="download-button"
      target="_blank"
      icon="download"
      category="primary"
      variant="default"
    />
    <gl-button
      v-if="environmentName && environmentPath"
      v-gl-tooltip.hover
      :aria-label="environmentTitle"
      :title="environmentTitle"
      :href="environmentPath"
      data-testid="environment"
      target="_blank"
      icon="external-link"
      category="primary"
      variant="default"
    />
  </gl-button-group>
</template>
