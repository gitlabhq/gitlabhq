<script>
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    BlobHeaderEdit,
    BlobContentEdit,
    GlLoadingIcon,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    fileName: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>
<template>
  <div class="form-group file-editor">
    <label>{{ s__('Snippets|File') }}</label>
    <div class="file-holder snippet">
      <blob-header-edit
        :value="fileName"
        data-qa-selector="snippet_file_name"
        @input="$emit('name-change', $event)"
      />
      <gl-loading-icon
        v-if="isLoading"
        :label="__('Loading snippet')"
        size="lg"
        class="loading-animation prepend-top-20 append-bottom-20"
      />
      <blob-content-edit
        v-else
        :value="value"
        :file-name="fileName"
        @input="$emit('input', $event)"
      />
    </div>
  </div>
</template>
