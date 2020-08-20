<script>
import { GlFormGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import { MAX_FILE_SIZE } from '../../constants';

export default {
  components: {
    GlFormGroup,
  },
  data() {
    return {
      file: null,
      fileError: null,
    };
  },
  fileLabel: __('Select file'),
  methods: {
    onInput(event) {
      [this.file] = event.target.files;

      this.validateFile();

      if (!this.fileError) {
        this.$emit('input', this.file);
      }
    },
    validateFile() {
      this.fileError = null;

      if (!this.file) {
        this.fileError = __('Please choose a file');
      } else if (this.file.size > MAX_FILE_SIZE) {
        this.fileError = __('Maximum file size is 2MB. Please select a smaller file.');
      }
    },
  },
};
</script>
<template>
  <gl-form-group
    class="gl-mt-5 gl-mb-3"
    :label="$options.fileLabel"
    label-for="file-input"
    :state="!Boolean(fileError)"
    :invalid-feedback="fileError"
  >
    <input
      id="file-input"
      ref="fileInput"
      class="gl-mt-3 gl-mb-2"
      type="file"
      accept="image/*"
      @input="onInput"
    />
  </gl-form-group>
</template>
