<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { setUrlParams, relativePathToAbsolute, getBaseURL } from '~/lib/utils/url_utility';

export const i18n = {
  btnCopyContentsTitle: __('Copy file contents'),
  btnDownloadTitle: __('Download'),
  btnRawTitle: s__('BlobViewer|Open raw'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdownItem,
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
    name: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    rawPath: {
      type: String,
      required: true,
    },
    activeViewerType: {
      type: String,
      required: true,
    },
    hasRenderError: {
      type: Boolean,
      required: true,
    },
    isBinary: {
      type: Boolean,
      required: true,
    },
    isEmpty: {
      type: Boolean,
      required: true,
    },
    overrideCopy: {
      type: Boolean,
      required: true,
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
  },
  computed: {
    copyFileContentsItem() {
      return {
        text: i18n.btnCopyContentsTitle,
        extraAttrs: {
          'data-testid': 'copy-contents-button',
          'data-clipboard-target': this.getBlobHashTarget,
          disabled: this.copyDisabled,
        },
      };
    },
    openRawItem() {
      return {
        text: i18n.btnRawTitle,
        href: this.rawPath,
        extraAttrs: {
          target: '_blank',
        },
      };
    },
    downloadItem() {
      return {
        text: i18n.btnDownloadTitle,
        href: this.downloadUrl,
        extraAttrs: {
          target: '_blank',
          'data-testid': 'download-button',
        },
      };
    },
    environmentItem() {
      return {
        text: this.environmentTitle,
        href: this.environmentPath,
        extraAttrs: {
          target: '_blank',
          'data-testid': 'environment',
        },
      };
    },
    showCopyButton() {
      return !this.hasRenderError && !this.isBinary;
    },
    copyDisabled() {
      return this.activeViewerType === 'rich';
    },
    getBlobHashTarget() {
      if (this.overrideCopy) {
        return null;
      }
      return `[data-blob-hash="${this.blobHash}"]`;
    },
    downloadUrl() {
      return setUrlParams({ inline: false }, relativePathToAbsolute(this.rawPath, getBaseURL()));
    },
    showEnvironmentItem() {
      return this.environmentName && this.environmentPath;
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
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown-item
      v-if="showCopyButton"
      data-testid="copy-item"
      :item="copyFileContentsItem"
      class="js-copy-blob-source-btn"
      @action="onCopy"
    />
    <gl-disclosure-dropdown-item v-if="!isBinary" data-testid="open-raw-item" :item="openRawItem" />
    <gl-disclosure-dropdown-item
      v-if="!isEmpty && canDownloadCode"
      data-test="download-item"
      :item="downloadItem"
    />
    <gl-disclosure-dropdown-item
      v-if="showEnvironmentItem"
      data-testid="environment-item"
      :item="environmentItem"
    />
  </div>
</template>
