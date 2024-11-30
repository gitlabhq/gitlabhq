<script>
import { GlModal, GlLink, GlSprintf, GlButton, GlAlert } from '@gitlab/ui';
import { validateFileFromAllowList } from '~/lib/utils/file_upload';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

export default {
  components: {
    GlModal,
    GlLink,
    GlSprintf,
    GlButton,
    GlAlert,
    UploadDropzone,
  },
  inject: {
    reassignmentCsvPath: {
      default: '',
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      fileName: null,
      fileContents: null,
      uploadError: false,
    };
  },
  computed: {
    dropzoneDescription() {
      return this.fileName ?? this.$options.i18n.dropzoneDescriptionText;
    },
  },
  methods: {
    reassignContributions() {
      this.$refs.form.submit();
    },
    isValidFileType(file) {
      return validateFileFromAllowList(file.name, this.$options.dropzoneAllowList);
    },
    clearError() {
      this.uploadError = false;
    },
    onChange(file) {
      this.clearError();
      this.fileName = file?.name;
      this.readFile(file);
    },
    onError() {
      this.uploadError = this.$options.i18n.errorMessage;
    },
    readFile(file) {
      const reader = new FileReader();
      reader.readAsText(file);
      reader.onload = (evt) => {
        this.fileContents = evt.target.result;
      };
    },
    close() {
      this.clearError();
      this.$refs[this.modalId].hide();
    },
  },
  dropzoneAllowList: ['.csv'],
  docsLink: helpPagePath('user/project/import/index', {
    anchor: 'reassign-contributions-and-memberships',
  }),
  i18n: {
    description: s__(
      'UserMapping|Use a CSV file to reassign contributions from placeholder users to existing group members. For more information, see %{linkStart}reassign contributions and memberships%{linkEnd}.',
    ),
    errorMessage: s__(
      'UserMapping|Could not upload the file. Check that the file follows the CSV template and try again.',
    ),
    dropzoneDescriptionText: s__(
      'UserMapping|Drop your file here or %{linkStart}click to upload%{linkEnd}.',
    ),
  },
  primaryAction: {
    text: s__('UserMapping|Reassign'),
  },
  cancelAction: {
    text: __('Cancel'),
  },
  csrf,
};
</script>
<template>
  <gl-modal
    :ref="modalId"
    :modal-id="modalId"
    :title="s__('UserMapping|Reassign with CSV file')"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="reassignContributions"
  >
    <gl-sprintf :message="$options.i18n.description">
      <template #link="{ content }">
        <gl-link :href="$options.docsLink" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
    <ol class="gl-ml-0 gl-mt-5">
      <li>
        <gl-button
          :href="reassignmentCsvPath"
          variant="link"
          icon="download"
          data-testid="csv-download-button"
          class="vertical-align-text-top"
          >{{ s__('UserMapping|Download the prefilled CSV template.') }}</gl-button
        >
      </li>
      <li>{{ s__('UserMapping|Review and complete the CSV file.') }}</li>
      <li>{{ s__('UserMapping|Upload the completed CSV file.') }}</li>
    </ol>
    <upload-dropzone
      class="gl-my-5"
      :is-file-valid="isValidFileType"
      :valid-file-mimetypes="$options.dropzoneAllowList"
      :should-update-input-on-file-drop="true"
      :single-file-selection="true"
      :enable-drag-behavior="false"
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
        {{ $options.i18n.errorMessage }}
      </template>
    </upload-dropzone>
    <gl-alert
      v-if="uploadError"
      data-testid="upload-error"
      variant="danger"
      :dismissible="false"
      class="gl-mb-5"
    >
      {{ uploadError }}
    </gl-alert>
    <gl-alert variant="warning" :dismissible="false">
      {{
        s__(
          'UserMapping|After you select "Reassign", users receive an email to accept the reassignment. Accepted reassignments cannot be undone, so check all data carefully before you continue.',
        )
      }}
    </gl-alert>
    <form ref="form" :action="reassignmentCsvPath" enctype="multipart/form-data" method="post">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <input :value="fileContents || false" type="hidden" name="file" />
    </form>
  </gl-modal>
</template>
