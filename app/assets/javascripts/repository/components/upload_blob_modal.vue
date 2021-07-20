<script>
import {
  GlModal,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlToggle,
  GlButton,
  GlAlert,
} from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { ContentTypeMultipartFormData } from '~/lib/utils/headers';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { trackFileUploadEvent } from '~/projects/upload_file_experiment_tracking';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  TARGET_BRANCH_LABEL,
  TOGGLE_CREATE_MR_LABEL,
} from '../constants';

const PRIMARY_OPTIONS_TEXT = __('Upload file');
const MODAL_TITLE = __('Upload New File');
const REMOVE_FILE_TEXT = __('Remove file');
const NEW_BRANCH_IN_FORK = __(
  'A new branch will be created in your fork and a new merge request will be started.',
);
const ERROR_MESSAGE = __('Error uploading file. Please try again.');

export default {
  components: {
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
    GlButton,
    UploadDropzone,
    GlAlert,
  },
  i18n: {
    COMMIT_LABEL,
    TARGET_BRANCH_LABEL,
    TOGGLE_CREATE_MR_LABEL,
    REMOVE_FILE_TEXT,
    NEW_BRANCH_IN_FORK,
  },
  props: {
    modalTitle: {
      type: String,
      default: MODAL_TITLE,
      required: false,
    },
    primaryBtnText: {
      type: String,
      default: PRIMARY_OPTIONS_TEXT,
      required: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    commitMessage: {
      type: String,
      required: true,
    },
    targetBranch: {
      type: String,
      required: true,
    },
    originalBranch: {
      type: String,
      required: true,
    },
    canPushCode: {
      type: Boolean,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    replacePath: {
      type: String,
      default: null,
      required: false,
    },
  },
  data() {
    return {
      commit: this.commitMessage,
      target: this.targetBranch,
      createNewMr: true,
      file: null,
      filePreviewURL: null,
      fileBinary: null,
      loading: false,
    };
  },
  computed: {
    primaryOptions() {
      return {
        text: this.primaryBtnText,
        attributes: [
          {
            variant: 'confirm',
            loading: this.loading,
            disabled: !this.formCompleted || this.loading,
          },
        ],
      };
    },
    cancelOptions() {
      return {
        text: SECONDARY_OPTIONS_TEXT,
        attributes: [
          {
            disabled: this.loading,
          },
        ],
      };
    },
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
    showCreateNewMrToggle() {
      return this.canPushCode && this.target !== this.originalBranch;
    },
    formCompleted() {
      return this.file && this.commit && this.target;
    },
  },
  methods: {
    setFile(file) {
      this.file = file;

      const fileUurlReader = new FileReader();

      fileUurlReader.readAsDataURL(this.file);

      fileUurlReader.onload = (e) => {
        this.filePreviewURL = e.target?.result;
      };
    },
    removeFile() {
      this.file = null;
      this.filePreviewURL = null;
    },
    submitForm() {
      return this.replacePath ? this.replaceFile() : this.uploadFile();
    },
    submitRequest(method, url) {
      return axios({
        method,
        url,
        data: this.formData(),
        headers: {
          ...ContentTypeMultipartFormData,
        },
      })
        .then((response) => {
          if (!this.replacePath) {
            trackFileUploadEvent('click_upload_modal_form_submit');
          }
          visitUrl(response.data.filePath);
        })
        .catch(() => {
          this.loading = false;
          createFlash({ message: ERROR_MESSAGE });
        });
    },
    formData() {
      const formData = new FormData();
      formData.append('branch_name', this.target);
      formData.append('create_merge_request', this.createNewMr);
      formData.append('commit_message', this.commit);
      formData.append('file', this.file);

      return formData;
    },
    replaceFile() {
      this.loading = true;

      // The PUT path can be geneated from $route (similar to "uploadFile") once router is connected
      // Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/332736
      return this.submitRequest('put', this.replacePath);
    },
    uploadFile() {
      this.loading = true;

      const {
        $route: {
          params: { path },
        },
      } = this;
      const uploadPath = joinPaths(this.path, path);

      return this.submitRequest('post', uploadPath);
    },
  },
  validFileMimetypes: [],
};
</script>
<template>
  <gl-form>
    <gl-modal
      :modal-id="modalId"
      :title="modalTitle"
      :action-primary="primaryOptions"
      :action-cancel="cancelOptions"
      @primary.prevent="submitForm"
    >
      <upload-dropzone
        class="gl-h-200! gl-mb-4"
        single-file-selection
        :valid-file-mimetypes="$options.validFileMimetypes"
        @change="setFile"
      >
        <div
          v-if="file"
          class="card upload-dropzone-card upload-dropzone-border gl-w-full gl-h-full gl-align-items-center gl-justify-content-center gl-p-3"
        >
          <img v-if="filePreviewURL" :src="filePreviewURL" class="gl-h-11" />
          <div>{{ formattedFileSize }}</div>
          <div>{{ file.name }}</div>
          <gl-button
            category="tertiary"
            variant="confirm"
            :disabled="loading"
            @click="removeFile"
            >{{ $options.i18n.REMOVE_FILE_TEXT }}</gl-button
          >
        </div>
      </upload-dropzone>
      <gl-form-group :label="$options.i18n.COMMIT_LABEL" label-for="commit_message">
        <gl-form-textarea v-model="commit" name="commit_message" :disabled="loading" />
      </gl-form-group>
      <gl-form-group
        v-if="canPushCode"
        :label="$options.i18n.TARGET_BRANCH_LABEL"
        label-for="branch_name"
      >
        <gl-form-input v-model="target" :disabled="loading" name="branch_name" />
      </gl-form-group>
      <gl-toggle
        v-if="showCreateNewMrToggle"
        v-model="createNewMr"
        :disabled="loading"
        :label="$options.i18n.TOGGLE_CREATE_MR_LABEL"
      />
      <gl-alert v-if="!canPushCode" variant="info" :dismissible="false" class="gl-mt-3">
        {{ $options.i18n.NEW_BRANCH_IN_FORK }}
      </gl-alert>
    </gl-modal>
  </gl-form>
</template>
