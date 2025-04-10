<script>
import { GlFormGroup, GlLink, GlSprintf, GlAlert, GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { validateFileFromAllowList } from '~/lib/utils/file_upload';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

export default {
  components: {
    GlFormGroup,
    GlLink,
    GlSprintf,
    GlButton,
    GlAlert,
    HelpIcon,
    MultiStepFormTemplate,
    GroupSelect,
    UploadDropzone,
  },
  props: {
    backButtonPath: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
    statusImportManifestPath: {
      type: String,
      required: true,
    },
    namespaceId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      fileName: null,
      file: null,
      groupId: this.namespaceId,
      uploadError: false,
    };
  },
  computed: {
    dropzoneDescription() {
      return (
        this.fileName ??
        s__('FileUpload|Drop your file here or %{linkStart}click to upload%{linkEnd}.')
      );
    },
  },
  methods: {
    handleGroupSelected(group) {
      this.groupId = group?.id ?? null;
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
      this.file = file;
    },
    onError() {
      this.uploadError = s__(
        'ManifestImport|Unable to upload the file. Please upload a valid XML file.',
      );
    },
    async onSubmit() {
      if (!this.uploadError) {
        if (this.file) {
          const formData = new FormData();
          formData.append('manifest', this.file);
          formData.append('group_id', this.groupId);

          try {
            await axios.post(this.formPath, formData);
            visitUrl(this.statusImportManifestPath);
          } catch (error) {
            const message =
              error?.response?.data?.errors?.join('. ') ||
              __('Something went wrong on our end. Please try again.');
            createAlert({
              message,
            });
          }
        } else {
          this.uploadError = s__('ManifestImport|Please upload a manifest file.');
        }
      }
    },
  },
  dropzoneAllowList: ['.xml'],
  manifestImportHelpLink: helpPagePath('user/project/import/manifest'),
};
</script>

<template>
  <multi-step-form-template
    :title="s__('ManifestImport|Manifest file import')"
    :current-step="3"
    :steps-total="3"
  >
    <template #form>
      <group-select
        :label="__('Group')"
        :initial-selection="namespaceId"
        :description="__('Choose the top-level group for your repository imports.')"
        input-name="group"
        input-id="group"
        block
        fluid-width
        @input="handleGroupSelected"
        @clear="handleGroupSelected"
      />
      <gl-form-group :label="__('Manifest')">
        <upload-dropzone
          class="gl-mb-5"
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
        <template #label-description>
          {{ __('Import multiple repositories by uploading a manifest file.') }}
          <gl-link :href="$options.manifestImportHelpLink" target="_blank"><help-icon /></gl-link>
        </template>
      </gl-form-group>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        :href="backButtonPath"
        data-testid="back-button"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
    <template #next>
      <gl-button category="primary" variant="confirm" data-testid="next-button" @click="onSubmit">
        {{ __('List available repositories') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
