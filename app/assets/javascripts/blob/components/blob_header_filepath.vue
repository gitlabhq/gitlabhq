<script>
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  components: {
    FileIcon,
    ClipboardButton,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  computed: {
    blobSize() {
      return numberToHumanSize(this.blob.size);
    },
    gfmCopyText() {
      return `\`${this.blob.path}\``;
    },
  },
};
</script>
<template>
  <div class="file-header-content d-flex align-items-center lh-100">
    <slot name="filepath-prepend"></slot>

    <template v-if="blob.path">
      <file-icon :file-name="blob.path" :size="16" aria-hidden="true" css-classes="mr-2" />
      <strong
        class="file-title-name mr-1 js-blob-header-filepath"
        data-qa-selector="file_title_content"
        >{{ blob.path }}</strong
      >
    </template>

    <small class="mr-2">{{ blobSize }}</small>

    <clipboard-button
      :text="blob.path"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="btn-clipboard btn-transparent lh-100 position-static"
    />
  </div>
</template>
