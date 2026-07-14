<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { setUrlParams, relativePathToAbsolute, getBaseURL } from '~/lib/utils/url_utility';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_DOWNLOAD_AS_MARKDOWN_TITLE,
  BTN_DOWNLOAD_AS_PDF_TITLE,
  BTN_RAW_TITLE,
  MARKDOWN_EXTENSIONS,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER,
} from './constants';

export default {
  name: 'BlobHeaderDefaultActions',
  i18n: {
    BTN_DOWNLOAD_AS_MARKDOWN_TITLE,
    BTN_DOWNLOAD_AS_PDF_TITLE,
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlDisclosureDropdown,
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
    fileType: {
      default: '',
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
  emits: ['copy'],
  computed: {
    downloadUrl() {
      return setUrlParams(
        { inline: false },
        { url: relativePathToAbsolute(this.rawPath, getBaseURL()) },
      );
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
    isPdfFile() {
      return this.fileType?.includes('pdf');
    },
    isMarkdownFile() {
      if (!this.rawPath) return false;
      const pathWithoutQuery = this.rawPath.split('?')[0];
      const ext = pathWithoutQuery.split('.').pop()?.toLowerCase();
      return MARKDOWN_EXTENSIONS.includes(ext);
    },
    showDownloadDropdown() {
      return !this.isEmpty && this.canDownloadCode && this.isMarkdownFile;
    },
    downloadDropdownItems() {
      return [
        {
          text: this.$options.i18n.BTN_DOWNLOAD_AS_MARKDOWN_TITLE,
          href: this.downloadUrl,
          // eslint-disable-next-line @gitlab/require-i18n-strings
          extraAttrs: { rel: 'noopener noreferrer' },
        },
        {
          text: this.$options.i18n.BTN_DOWNLOAD_AS_PDF_TITLE,
          action: () => {
            document.querySelectorAll('img').forEach((img) => img.setAttribute('loading', 'eager'));
            document
              .querySelectorAll('details')
              .forEach((detail) => detail.setAttribute('open', ''));
            window.print();
          },
        },
      ];
    },
    openInNewWindowUrl() {
      return setUrlParams(
        { inline: true },
        { url: relativePathToAbsolute(this.rawPath, getBaseURL()) },
      );
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
  <gl-button-group
    class="gl-hidden @sm/panel:gl-inline-flex"
    data-testid="default-actions-container"
  >
    <slot name="prepend"></slot>
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
    <gl-disclosure-dropdown
      v-if="showDownloadDropdown"
      v-gl-tooltip.hover
      :title="$options.BTN_DOWNLOAD_TITLE"
      :aria-label="$options.BTN_DOWNLOAD_TITLE"
      :items="downloadDropdownItems"
      icon="download"
      category="primary"
      variant="default"
      data-testid="download-dropdown"
    />
    <gl-button
      v-else-if="!isEmpty && canDownloadCode"
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
      v-if="!isEmpty && isPdfFile"
      v-gl-tooltip.hover
      :aria-label="s__('BlobViewer|Open in a new window')"
      :title="s__('BlobViewer|Open in a new window')"
      :href="openInNewWindowUrl"
      data-testid="open-new-window-button"
      target="_blank"
      rel="noopener noreferrer"
      icon="external-link"
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
