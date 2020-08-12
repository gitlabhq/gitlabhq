<script>
import SnippetBlobEdit from './snippet_blob_edit.vue';

export default {
  components: {
    SnippetBlobEdit,
  },
  props: {
    blobs: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div class="form-group file-editor">
    <label for="snippet_file_path">{{ s__('Snippets|File') }}</label>
    <template v-if="blobs.length">
      <snippet-blob-edit v-for="blob in blobs" :key="blob.name" :blob="blob" v-on="$listeners" />
    </template>
    <snippet-blob-edit v-else v-on="$listeners" />
  </div>
</template>
