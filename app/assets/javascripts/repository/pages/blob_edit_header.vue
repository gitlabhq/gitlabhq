<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import {
  getParameterByName,
  visitUrl,
  joinPaths,
  mergeUrlParams,
  removeParams,
} from '~/lib/utils/url_utility';
import { buildApiUrl } from '~/api/api_utils';
import { VARIANT_INFO } from '~/alert';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert';
import getRefMixin from '../mixins/get_ref';
import {
  prepareEditFormData,
  prepareCreateFormData,
  prepareDataForApiEdit,
} from '../utils/edit_form_data_utils';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';

export default {
  UPDATE_FILE_PATH: '/api/:version/projects/:id/repository/files/:file_path',
  COMMIT_FILE_PATH: '/api/:version/projects/:id/repository/commits',
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
    'targetProjectId',
    'targetProjectPath',
    'nextForkBranchName',
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
    successMessageForAlert() {
      return (isNewBranch, createMergeRequestNotChosen) => {
        let message = __(
          'Your %{changesLinkStart}changes%{changesLinkEnd} have been committed successfully.',
        );

        if (isNewBranch && createMergeRequestNotChosen) {
          // Use canPushToBranch to determine if user is working on a fork
          const mrMessage = this.canPushToBranch
            ? __('You can now submit a merge request to get this change into the original branch.')
            : __(
                'You can now submit a merge request to get this change into the original project.',
              );
          message += ` ${mrMessage}`;
        }

        return message;
      };
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
    getUpdatePath(baseUrl, options) {
      const { targetPath, branch, filePath } = options;
      const urlObj = new URL(baseUrl);
      urlObj.pathname = joinPaths(targetPath, '-/blob', branch, filePath);
      return urlObj.toString();
    },
    getResultingBranch(responseData, formData) {
      return responseData.branch || formData.branch_name || formData.original_branch;
    },
    editBlob(originalFormData) {
      const filePathChanged = originalFormData.file_path !== this.originalFilePath;

      if (filePathChanged) {
        // Use Commits API for file rename/move operations
        return this.editBlobWithCommitsApi(originalFormData);
      }

      // Use Repository Files API for content-only updates
      return this.editBlobWithUpdateFileApi(originalFormData);
    },
    editBlobWithUpdateFileApi(originalFormData) {
      const url = buildApiUrl(this.$options.UPDATE_FILE_PATH)
        .replace(':id', this.targetProjectId)
        .replace(':file_path', encodeURIComponent(this.originalFilePath));

      const data = {
        ...prepareDataForApiEdit(originalFormData),
        content: originalFormData.file,
        file_path: originalFormData.file_path,
        id: this.targetProjectId,
        last_commit_id: originalFormData.last_commit_sha,
      };

      return axios.put(url, data);
    },
    editBlobWithCommitsApi(originalFormData) {
      const url = buildApiUrl(this.$options.COMMIT_FILE_PATH).replace(':id', this.targetProjectId);

      const action = {
        action: 'move',
        file_path: originalFormData.file_path,
        previous_path: this.originalFilePath,
        content: originalFormData.file,
        last_commit_id: originalFormData.last_commit_sha,
      };

      const data = {
        ...prepareDataForApiEdit(originalFormData),
        actions: [action],
      };

      return axios.post(url, data);
    },
    editBlobWithController(originalFormData) {
      return axios({
        method: 'put',
        url: this.updatePath,
        data: originalFormData,
      });
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
      const originalFormData = prepareEditFormData(formData, {
        fileContent: this.fileContent,
        filePath: this.filePath,
        lastCommitSha: this.lastCommitSha,
        fromMergeRequestIid: this.fromMergeRequestIid,
        forkBranchName: this.canPushToBranch ? undefined : this.nextForkBranchName,
      });

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
      const originalFormData = prepareCreateFormData(formData, {
        filePath: this.filePath,
        fileContent: this.fileContent,
      });

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
    handleEditBlobSuccess(responseData, formData) {
      const resultingBranch = this.getResultingBranch(responseData, formData);
      const isNewBranch = this.originalBranch !== resultingBranch;
      const urlString = window.location.href;

      if (this.shouldRedirectToExistingMR(resultingBranch)) {
        this.redirectToExistingMergeRequest(urlString);
      } else if (!this.canPushToBranch) {
        this.redirectToForkMergeRequest(urlString, resultingBranch);
      } else if (this.shouldCreateNewMR(formData, isNewBranch)) {
        this.redirectToCreateMergeRequest(resultingBranch);
      } else {
        this.redirectToBlobWithAlert({
          urlString,
          resultingBranch,
          responseData,
          formData,
          isNewBranch,
        });
      }
    },
    shouldRedirectToExistingMR(resultingBranch) {
      return (
        this.fromMergeRequestIid &&
        resultingBranch === this.originalBranch &&
        !this.branchAllowsCollaboration
      );
    },
    shouldCreateNewMR(formData, isNewBranch) {
      return formData.create_merge_request && isNewBranch;
    },
    redirectToExistingMergeRequest(url) {
      const urlCopy = new URL(url);
      urlCopy.pathname = joinPaths(
        this.projectPath,
        '/-/merge_requests/',
        this.fromMergeRequestIid,
      );
      const cleanUrl = removeParams(['from_merge_request_iid'], urlCopy.toString());
      visitUrl(cleanUrl);
    },
    redirectToCreateMergeRequest(resultingBranch) {
      const mrUrl = mergeUrlParams(
        { [MR_SOURCE_BRANCH]: resultingBranch },
        this.newMergeRequestPath,
      );
      visitUrl(mrUrl);
    },
    redirectToForkMergeRequest(url, resultingBranch) {
      const urlCopy = new URL(url);
      urlCopy.pathname = joinPaths(this.targetProjectPath, '/-/merge_requests/new');

      const mrParams = {
        'merge_request[source_project_id]': this.targetProjectId,
        'merge_request[source_branch]': resultingBranch,
        'merge_request[target_project_id]': this.projectId,
        'merge_request[target_branch]': this.originalBranch,
      };

      const finalMrUrl = mergeUrlParams(mrParams, urlCopy.toString());
      visitUrl(finalMrUrl);
    },
    redirectToBlobWithAlert(options) {
      const { urlString, resultingBranch, responseData, formData, isNewBranch } = options;
      const cleanUrl = removeParams(['from_merge_request_iid'], urlString);
      const successPath = this.getUpdatePath(cleanUrl, {
        targetPath: this.targetProjectPath,
        branch: resultingBranch,
        filePath: responseData.file_path || formData.file_path,
      });
      const createMergeRequestNotChosen = !formData.create_merge_request;

      const message = this.successMessageForAlert(isNewBranch, createMergeRequestNotChosen);

      saveAlertToLocalStorage({
        message,
        messageLinks: { changesLink: successPath },
        variant: VARIANT_INFO,
      });

      visitUrl(successPath);
    },
    handleControllerSuccess(responseData) {
      if (responseData.filePath) {
        visitUrl(responseData.filePath);
      } else {
        this.handleError(this.errorMessage);
      }
    },
    handleError(message, errorCode = null) {
      if (!message) return;
      // Returns generic '403 Forbidden' error message
      // Custom message will be added in https://gitlab.com/gitlab-org/gitlab/-/issues/569115
      this.error = errorCode === 403 ? this.errorMessage : message;
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
