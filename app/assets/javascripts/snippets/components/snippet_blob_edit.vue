<script>
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';

export default {
  components: {
    BlobHeaderEdit,
    BlobContentEdit,
  },
  inheritAttrs: false,
  props: {
    fileName: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    emitFileNameChange(newFileName) {
      this.$emit('name-change', newFileName);
    },
  },
};
</script>
<template>
  <div class="form-group file-editor">
    <label>{{ s__('Snippets|File') }}</label>
    <div class="file-holder snippet">
      <blob-header-edit :value="fileName" @input="emitFileNameChange" />
      <blob-content-edit v-bind="$attrs" :file-name="fileName" v-on="$listeners" />
    </div>
  </div>
</template>
