<script>
import { GlLink, GlSprintf, GlAlert, GlFormGroup } from '@gitlab/ui';
import { validateFileFromAllowList } from '~/lib/utils/file_upload';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { s__ } from '~/locale';

const i18n = Object.freeze({
  description: s__('Integrations|Drag your file here or %{linkStart}click to upload%{linkEnd}.'),
  errorMessage: s__(
    'Integrations|Error: You are trying to upload something other than an allowed file.',
  ),
  confirmMessage: s__('Integrations|Drop your file to start the upload.'),
});

export default {
  name: 'UploadDropzoneField',
  components: {
    UploadDropzone,
    GlLink,
    GlSprintf,
    GlAlert,
    GlFormGroup,
  },
  i18n,
  props: {
    name: {
      type: String,
      required: true,
      default: null,
    },
    label: {
      type: String,
      required: true,
      default: null,
    },
    helpText: {
      type: String,
      required: false,
      default: null,
    },
    fileInputName: {
      type: String,
      required: true,
      default: null,
    },
    allowList: {
      type: Array,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: i18n.description,
    },
    errorMessage: {
      type: String,
      required: false,
      default: i18n.errorMessage,
    },
    confirmMessage: {
      type: String,
      required: false,
      default: i18n.confirmMessage,
    },
  },
  data() {
    return {
      fileName: null,
      fileContents: null,
      uploadError: false,
      inputDisabled: true,
    };
  },
  computed: {
    dropzoneDescription() {
      return this.fileName ?? this.description;
    },
  },
  methods: {
    clearError() {
      this.uploadError = false;
    },
    onChange(file) {
      this.clearError();
      this.inputDisabled = false;
      this.fileName = file?.name;
      this.readFile(file);
    },
    isValidFileType(file) {
      return validateFileFromAllowList(file.name, this.allowList);
    },
    onError() {
      this.uploadError = this.errorMessage;
    },
    readFile(file) {
      const reader = new FileReader();
      reader.readAsText(file);
      reader.onload = (evt) => {
        this.fileContents = evt.target.result;
      };
    },
  },
};
</script>
<template>
  <gl-form-group :label="label" :label-for="name">
    <upload-dropzone
      input-field-name="service[dropzone_file_name]"
      :is-file-valid="isValidFileType"
      :valid-file-mimetypes="allowList"
      :should-update-input-on-file-drop="true"
      :single-file-selection="true"
      :enable-drag-behavior="false"
      :drop-to-start-message="confirmMessage"
      @change="onChange"
      @error="onError"
    >
      <template #upload-text="{ openFileUpload }">
        <gl-sprintf :message="dropzoneDescription">
          <template #link="{ content }">
            <gl-link @click.stop="openFileUpload">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <template #invalid-drag-data-slot>
        {{ errorMessage }}
      </template>
    </upload-dropzone>
    <gl-alert v-if="uploadError" variant="danger" :dismissible="true" @dismiss="clearError">
      {{ uploadError }}
    </gl-alert>
    <input :name="name" type="hidden" :disabled="inputDisabled" :value="fileContents || false" />
    <input
      :name="fileInputName"
      type="hidden"
      :disabled="inputDisabled"
      :value="fileName || false"
    />
    <span>{{ helpText }}</span>
  </gl-form-group>
</template>
