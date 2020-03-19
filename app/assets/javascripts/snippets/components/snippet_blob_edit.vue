<script>
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';

export default {
  components: {
    BlobHeaderEdit,
    BlobContentEdit,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      name: this.fileName,
      blobContent: this.content,
    };
  },
};
</script>
<template>
  <div class="form-group file-editor">
    <label>{{ s__('Snippets|File') }}</label>
    <div class="file-holder snippet">
      <blob-header-edit v-model="name" />
      <blob-content-edit v-model="blobContent" :file-name="name" />
    </div>
  </div>
</template>
