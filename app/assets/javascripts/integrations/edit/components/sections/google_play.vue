<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { sprintf, s__ } from '~/locale';
import UploadDropzoneField from '../upload_dropzone_field.vue';
import Connection from './connection.vue';

export default {
  name: 'IntegrationSectionGooglePlay',
  components: {
    Connection,
    UploadDropzoneField,
  },
  data() {
    return {
      dropzoneAllowList: ['.JSON'],
    };
  },
  i18n: {
    dropzoneDescription: s__(
      'GooglePlay|Drag your key file here or %{linkStart}click to upload%{linkEnd}.',
    ),
    dropzoneErrorMessage: s__(
      "GooglePlay|Error: The file you're trying to upload is not a service account key.",
    ),
    dropzoneConfirmMessage: s__('GooglePlay|Drag your key file to start the upload.'),
    dropzoneEmptyInputName: s__('GooglePlay|Service account key (.JSON)'),
    dropzoneNonEmptyInputName: s__(
      'GooglePlay|Upload a new service account key (replace %{currentFileName})',
    ),
    dropzoneNoneEmpyInputHelp: s__(
      'GooglePlay|Leave empty to use your current service account key.',
    ),
  },
  computed: {
    ...mapGetters(['propsSource']),
    dynamicFields() {
      return this.propsSource.fields.filter(
        (field) => field.name !== 'service_account_key_file_name',
      );
    },
    fileNameField() {
      return this.propsSource.fields.find(
        (field) => field.name === 'service_account_key_file_name',
      );
    },
    dropzoneLabel() {
      return this.fileNameField.value
        ? sprintf(this.$options.i18n.dropzoneNonEmptyInputName, {
            currentFileName: this.fileNameField.value,
          })
        : this.$options.i18n.dropzoneEmptyInputName;
    },
    dropzoneHelpText() {
      return this.fileNameField.value ? this.$options.i18n.dropzoneNoneEmpyInputHelp : '';
    },
  },
};
</script>

<template>
  <span>
    <connection :fields="dynamicFields" />

    <upload-dropzone-field
      name="service[service_account_key]"
      :label="dropzoneLabel"
      :help-text="dropzoneHelpText"
      file-input-name="service[service_account_key_file_name]"
      :allow-list="dropzoneAllowList"
      :description="$options.i18n.dropzoneDescription"
      :error-message="$options.i18n.dropzoneErrorMessage"
      :confirm-message="$options.i18n.dropzoneConfirmMessage"
    />
  </span>
</template>
