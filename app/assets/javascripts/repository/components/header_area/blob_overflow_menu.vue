<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { setUrlParams, relativePathToAbsolute, getBaseURL } from '~/lib/utils/url_utility';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';

export const i18n = {
  dropdownLabel: __('Actions'),
  btnCopyContentsTitle: __('Copy file contents'),
  btnDownloadTitle: __('Download'),
  btnRawTitle: s__('BlobViewer|Open raw'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltipDirective,
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
    richViewer: {
      type: Object,
      required: false,
      default: () => {},
    },
    simpleViewer: {
      type: Object,
      required: false,
      default: () => {},
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
    activeViewerType() {
      if (this.$route?.query?.plain !== '1') {
        const richViewer = document.querySelector('.blob-viewer[data-type="rich"]');
        if (richViewer) {
          return RICH_BLOB_VIEWER;
        }
      }
      return SIMPLE_BLOB_VIEWER;
    },
    viewer() {
      return this.activeViewerType === RICH_BLOB_VIEWER ? this.richViewer : this.simpleViewer;
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
    downloadUrl() {
      return setUrlParams({ inline: false }, relativePathToAbsolute(this.rawPath, getBaseURL()));
    },
    copyDisabled() {
      return this.activeViewerType === RICH_BLOB_VIEWER;
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
    showDefaultActions() {
      return (
        this.showCopyButton ||
        !this.isBinary ||
        (!this.isEmpty && this.canDownloadCode) ||
        (this.environmentName && this.environmentPath)
      );
    },
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
    <gl-disclosure-dropdown
      v-if="showDefaultActions"
      v-gl-tooltip-directive.hover="$options.i18n.dropdownLabel"
      no-caret
      icon="ellipsis_v"
      data-testid="default-actions-container"
      :toggle-text="$options.i18n.dropdownLabel"
      text-sr-only
    >
      <gl-disclosure-dropdown-item
        v-if="showCopyButton"
        :item="copyFileContentsItem"
        class="js-copy-blob-source-btn"
        @action="onCopy"
      />
      <gl-disclosure-dropdown-item v-if="!isBinary" :item="openRawItem" />
      <gl-disclosure-dropdown-item v-if="!isEmpty && canDownloadCode" :item="downloadItem" />
      <gl-disclosure-dropdown-item
        v-if="environmentName && environmentPath"
        :item="environmentItem"
      />
    </gl-disclosure-dropdown>
  </div>
</template>
