<script>
import FileIcon from '~/vue_shared/components/file_icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

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
    <slot name="filepathPrepend"></slot>

    <template v-if="blob.path">
      <file-icon :file-name="blob.path" :size="18" aria-hidden="true" css-classes="mr-2" />
      <strong class="file-title-name qa-file-title-name mr-1 js-blob-header-filepath">{{
        blob.path
      }}</strong>
    </template>

    <small class="mr-2">{{ blobSize }}</small>

    <clipboard-button
      :text="blob.path"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      css-class="btn-clipboard btn-transparent lh-100 position-static"
    />
  </div>
</template>
