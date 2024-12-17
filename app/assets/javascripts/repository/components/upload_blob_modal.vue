<script>
import { GlButton } from '@gitlab/ui';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import { contentTypeMultipartFormData } from '~/lib/utils/headers';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';

export default {
  components: {
    GlButton,
    UploadDropzone,
    FileIcon,
    CommitChangesModal,
  },
  i18n: {
    REMOVE_FILE_TEXT: __('Remove file'),
    ERROR_MESSAGE: __('Error uploading file. Please try again.'),
  },
  props: {
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
    canPushToBranch: {
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
    emptyRepo: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      file: null,
      filePreviewURL: null,
      loading: false,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
    isValid() {
      return Boolean(this.file);
    },
  },
  methods: {
    show() {
      this.$refs[this.modalId].show();
    },
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
    submitForm(formData) {
      return this.replacePath ? this.replaceFile(formData) : this.uploadFile(formData);
    },
    submitRequest(method, url, formData) {
      this.loading = true;

      formData.append('file', this.file);

      return axios({
        method,
        url,
        data: formData,
        headers: {
          ...contentTypeMultipartFormData,
        },
      })
        .then((response) => {
          visitUrl(response.data.filePath);
        })
        .catch((e) => {
          logError(
            `Failed to ${this.replacePath ? 'replace' : 'upload'} file. See exception details for more information.`,
            e,
          );
          createAlert({ message: this.$options.i18n.ERROR_MESSAGE });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    replaceFile(formData) {
      // The PUT path can be generated from $route (similar to "uploadFile") once router is connected
      // Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/332736
      return this.submitRequest('put', this.replacePath, formData);
    },
    uploadFile(formData) {
      const {
        $route: {
          params: { path },
        },
      } = this;
      const uploadPath = joinPaths(this.path, path);

      return this.submitRequest('post', uploadPath, formData);
    },
  },
  validFileMimetypes: [],
};
</script>
<template>
  <commit-changes-modal
    :ref="modalId"
    :modal-id="modalId"
    :commit-message="commitMessage"
    :target-branch="targetBranch"
    :original-branch="originalBranch"
    :can-push-code="canPushCode"
    :can-push-to-branch="canPushToBranch"
    :valid="isValid"
    :loading="loading"
    :empty-repo="emptyRepo"
    data-testid="upload-blob-modal"
    @submit-form="submitForm"
  >
    <template #body>
      <upload-dropzone
        class="gl-mb-6 gl-h-26"
        single-file-selection
        :valid-file-mimetypes="$options.validFileMimetypes"
        :is-file-valid="() => true"
        @change="setFile"
      >
        <div
          v-if="file"
          class="card upload-dropzone-card upload-dropzone-border gl-h-full gl-w-full gl-items-center gl-justify-center gl-p-3"
        >
          <file-icon :file-name="file.name" :size="24" />
          <div class="gl-mb-2">
            {{ file.name }}
            &middot;
            <span class="gl-text-subtle">{{ formattedFileSize }}</span>
          </div>
          <gl-button
            category="tertiary"
            variant="confirm"
            :disabled="loading"
            @click="removeFile"
            >{{ $options.i18n.REMOVE_FILE_TEXT }}</gl-button
          >
        </div>
      </upload-dropzone>
    </template>
  </commit-changes-modal>
</template>
