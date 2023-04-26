<script>
import { GlBadge } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  components: {
    FileIcon,
    ClipboardButton,
    GlBadge,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    showPath: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    blobSize() {
      return numberToHumanSize(this.blob.size);
    },
    gfmCopyText() {
      return `\`${this.blob.path}\``;
    },
    showLfsBadge() {
      return this.blob.storedExternally && this.blob.externalStorage === 'lfs';
    },
    fileName() {
      if (this.showPath) {
        return this.blob.path;
      }

      return this.blob.name;
    },
  },
};
</script>
<template>
  <div class="file-header-content d-flex align-items-center lh-100">
    <slot name="filepath-prepend"></slot>

    <template v-if="fileName">
      <file-icon :file-name="fileName" :size="16" aria-hidden="true" css-classes="gl-mr-3" />
      <strong
        class="file-title-name mr-1 js-blob-header-filepath"
        data-qa-selector="file_title_content"
        >{{ fileName }}</strong
      >
    </template>

    <clipboard-button
      :text="blob.path"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="gl-mr-2"
    />

    <small class="gl-mr-3">{{ blobSize }}</small>

    <gl-badge v-if="showLfsBadge">{{ __('LFS') }}</gl-badge>
  </div>
</template>
