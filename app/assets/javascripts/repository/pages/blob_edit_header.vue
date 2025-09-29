<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { getParameterByName, visitUrl, joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';
import { buildApiUrl } from '~/api/api_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getRefMixin from '../mixins/get_ref';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';

export default {
  UPDATE_FILE_PATH: '/api/:version/projects/:id/repository/files/:file_path',
  components: {
    PageHeading,
    CommitChangesModal,
    GlButton,
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
  inject: [
    'action',
    'editor',
    'updatePath',
    'cancelPath',
    'originalBranch',
    'targetBranch',
    'blobName',
    'canPushCode',
    'canPushToBranch',
    'emptyRepo',
    'branchAllowsCollaboration',
    'lastCommitSha',
    'projectId',
    'projectPath',
    'newMergeRequestPath',
  ],
  data() {
    return {
      isCommitChangeModalOpen: false,
      fileContent: null,
      filePath: null,
      originalFilePath: null,
      isLoading: false,
      error: null,
    };
  },
  computed: {
    updateModalId() {
      return uniqueId('update-modal');
    },
    isEditBlob() {
      return this.action === 'update';
    },
    updateModalCommitMessage() {
      return this.isEditBlob
        ? sprintf(__('Edit %{name}'), { name: this.blobName })
        : __('Add new file');
    },
    fromMergeRequestIid() {
      return getParameterByName('from_merge_request_iid') || '';
    },
    headerText() {
      return this.isEditBlob ? __('Edit file') : __('New file');
    },
    errorMessage() {
      return this.isEditBlob
        ? __('An error occurred editing the blob')
        : __('An error occurred creating the blob');
    },
  },
  methods: {
    handleCancelButtonClick() {
      window.onbeforeunload = null;
    },
    openModal() {
      const filePath = this.editor.filepathFormMediator?.$filenameInput?.val();
      if (!filePath) {
        this.editor.filepathFormMediator?.toggleValidationError(true);
        return;
      }
      this.error = null;
      this.fileContent = this.editor.getFileContent();
      this.filePath = filePath;
      this.originalFilePath = this.editor.getOriginalFilePath();
      this.$refs[this.updateModalId].show();
    },
    prepareFormData(formData) {
      formData.append('file', this.fileContent);
      formData.append('file_path', this.filePath);
      formData.append('last_commit_sha', this.lastCommitSha);
      formData.append('from_merge_request_iid', this.fromMergeRequestIid);

      return Object.fromEntries(formData);
    },
    prepareControllerFormData(formData) {
      formData.append('file', this.fileContent);
      formData.append('file_path', this.filePath);
      formData.append('last_commit_sha', this.lastCommitSha);
      formData.append('from_merge_request_iid', this.fromMergeRequestIid);

      return Object.fromEntries(formData);
    },
    handleError(message, errorCode = null) {
      if (!message) return;
      // Returns generic '403 Forbidden' error message
      // Custom message will be added in https://gitlab.com/gitlab-org/gitlab/-/issues/569115
      this.error = errorCode === 403 ? this.errorMessage : message;
    },
    async handleFormSubmit(formData) {
      this.error = null;
      this.isLoading = true;

      if (this.isEditBlob) {
        this.handleEditFormSubmit(formData);
      } else {
        this.handleCreateFormSubmit(formData);
      }
    },
    async handleEditFormSubmit(formData) {
      const originalFormData = this.prepareFormData(formData);

      try {
        const response = this.glFeatures.blobEditRefactor
          ? await this.editBlob(originalFormData)
          : await this.editBlobWithController(originalFormData);
        const { data: responseData } = response;

        if (responseData.error) {
          this.handleError(responseData.error);
          return;
        }

        if (this.glFeatures.blobEditRefactor) {
          this.handleEditBlobSuccess(responseData, originalFormData);
        } else {
          this.handleControllerSuccess(responseData);
        }
      } catch (error) {
        const errorMessage =
          error.response?.data?.message || error.response?.data?.error || this.errorMessage;
        this.handleError(errorMessage, error.response?.status);
      } finally {
        this.isLoading = false;
      }
    },
    async handleCreateFormSubmit(formData) {
      formData.append('file_name', this.filePath);
      formData.append('content', this.fileContent);

      // Object.fromEntries is used here to handle potential line ending mutations in `FormData`.
      // `FormData` uses the "multipart/form-data" format (RFC 2388), which follows MIME data stream rules (RFC 2046).
      // These specifications require line breaks to be represented as CRLF sequences in the canonical form.
      // See https://stackoverflow.com/questions/69835705/formdata-textarea-puts-r-carriage-return-when-sent-with-post for more details.
      const originalFormData = Object.fromEntries(formData);

      try {
        const response = await axios({
          method: 'post',
          url: this.updatePath,
          data: originalFormData,
        });

        const { data: responseData } = response;

        if (responseData.error) {
          this.handleError(responseData.error);
          return;
        }

        this.handleControllerSuccess(responseData);
      } catch (error) {
        const errorMessage =
          error.response?.data?.message || error.response?.data?.error || this.errorMessage;
        this.handleError(errorMessage, error.response?.status);
      } finally {
        this.isLoading = false;
      }
    },
    editBlob(originalFormData) {
      const url = buildApiUrl(this.$options.UPDATE_FILE_PATH)
        .replace(':id', this.projectId)
        .replace(':file_path', encodeURIComponent(this.originalFilePath));

      const data = {
        branch: originalFormData.branch_name || originalFormData.original_branch,
        commit_message: originalFormData.commit_message,
        content: originalFormData.file,
        file_path: originalFormData.file_path,
        id: this.projectId,
        last_commit_id: originalFormData.last_commit_sha,
      };

      // Only include start_branch when creating a new branch
      if (
        originalFormData.branch_name &&
        originalFormData.branch_name !== originalFormData.original_branch
      ) {
        data.start_branch = originalFormData.original_branch;
      }

      return axios.put(url, data);
    },
    editBlobWithController(originalFormData) {
      return axios({
        method: 'put',
        url: this.updatePath,
        data: originalFormData,
      });
    },
    handleEditBlobSuccess(responseData, formData) {
      if (formData.create_merge_request && this.originalBranch !== responseData.branch) {
        const mrUrl = mergeUrlParams(
          { [MR_SOURCE_BRANCH]: responseData.branch },
          this.newMergeRequestPath,
        );
        visitUrl(mrUrl);
      } else {
        visitUrl(this.getUpdatePath(responseData.branch, responseData.file_path));
      }
    },
    handleControllerSuccess(responseData) {
      if (responseData.filePath) {
        visitUrl(responseData.filePath);
      } else {
        this.handleError(this.errorMessage);
      }
    },
    getUpdatePath(branch, filePath) {
      const url = new URL(window.location.href);
      url.pathname = joinPaths(this.projectPath, '-/blob', branch, filePath);
      return url.toString();
    },
  },
  i18n: {
    cancelButtonText: __('Cancel'),
    commitButtonText: __('Commit changes'),
    confirmationMessage: __('Leave edit mode? All unsaved changes will be lost.'),
  },
};
</script>

<template>
  <div>
    <page-heading :heading="headerText" class="gl-mb-3">
      <template #actions>
        <gl-button
          :data-confirm="$options.i18n.confirmationMessage"
          :href="cancelPath"
          data-confirm-btn-variant="danger"
          data-testid="blob-edit-header-cancel-button"
          @click="handleCancelButtonClick"
          >{{ $options.i18n.cancelButtonText }}</gl-button
        >
        <gl-button
          variant="confirm"
          data-testid="blob-edit-header-commit-button"
          @click="openModal"
        >
          {{ $options.i18n.commitButtonText }}
        </gl-button>
      </template>
    </page-heading>
    <commit-changes-modal
      :ref="updateModalId"
      :modal-id="updateModalId"
      :commit-message="updateModalCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :empty-repo="emptyRepo"
      :can-push-to-branch="canPushToBranch"
      :branch-allows-collaboration="branchAllowsCollaboration"
      :loading="isLoading"
      :error="error"
      @submit-form="handleFormSubmit"
    />
  </div>
</template>
