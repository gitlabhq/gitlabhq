<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { sprintf, s__ } from '~/locale';
import UploadDropzoneField from '../upload_dropzone_field.vue';
import Connection from './connection.vue';

export default {
  name: 'IntegrationSectionAppleAppStore',
  components: {
    Connection,
    UploadDropzoneField,
  },
  data() {
    return {
      dropzoneAllowList: ['.p8'],
    };
  },
  i18n: {
    dropzoneDescription: s__(
      'AppleAppStore|Drag your Private Key file here or %{linkStart}click to upload%{linkEnd}.',
    ),
    dropzoneErrorMessage: s__(
      'AppleAppStore|Error: You are trying to upload something other than a Private Key file.',
    ),
    dropzoneConfirmMessage: s__('AppleAppStore|Drop your Private Key file to start the upload.'),
    dropzoneEmptyInputName: s__('AppleAppStore|The Apple App Store Connect Private Key (.p8)'),
    dropzoneNonEmptyInputName: s__(
      'AppleAppStore|Upload a new Apple App Store Connect Private Key (replace %{currentFileName})',
    ),
    dropzoneNonEmptyInputHelp: s__('AppleAppStore|Leave empty to use your current Private Key.'),
  },
  computed: {
    ...mapGetters(['propsSource']),
    dynamicFields() {
      return this.propsSource.fields.filter(
        (field) => field.name !== 'app_store_private_key_file_name',
      );
    },
    fileNameField() {
      return this.propsSource.fields.find(
        (field) => field.name === 'app_store_private_key_file_name',
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
      return this.fileNameField.value ? this.$options.i18n.dropzoneNonEmptyInputHelp : '';
    },
  },
};
</script>

<template>
  <span>
    <connection :fields="dynamicFields" />

    <upload-dropzone-field
      name="service[app_store_private_key]"
      :label="dropzoneLabel"
      :help-text="dropzoneHelpText"
      file-input-name="service[app_store_private_key_file_name]"
      :allow-list="dropzoneAllowList"
      :description="$options.i18n.dropzoneDescription"
      :error-message="$options.i18n.dropzoneErrorMessage"
      :confirm-message="$options.i18n.dropzoneConfirmMessage"
    />
  </span>
</template>
