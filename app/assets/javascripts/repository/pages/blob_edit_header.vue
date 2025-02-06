<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { getParameterByName, visitUrl } from '~/lib/utils/url_utility';
import getRefMixin from '../mixins/get_ref';

export default {
  components: {
    CommitChangesModal,
    GlButton,
  },
  mixins: [getRefMixin],
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
  ],
  data() {
    return {
      isCommitChangeModalOpen: false,
      fileContent: null,
      filePath: null,
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
      this.error = null;
      this.fileContent = this.editor.getFileContent();
      this.filePath = this.editor.filepathFormMediator?.$filenameInput?.val();
      this.$refs[this.updateModalId].show();
    },
    handleError(message) {
      if (!message) return;
      this.error = message;
    },
    handleFormSubmit(formData) {
      this.error = null;
      this.isLoading = true;
      if (this.isEditBlob) {
        formData.append('file', this.fileContent);
        formData.append('file_path', this.filePath);
        formData.append('last_commit_sha', this.lastCommitSha);
        formData.append('from_merge_request_iid', this.fromMergeRequestIid);
      } else {
        formData.append('file_name', this.filePath);
        formData.append('content', this.fileContent);
      }

      // Object.fromEntries is used here to handle potential line ending mutations in `FormData`.
      // `FormData` uses the "multipart/form-data" format (RFC 2388), which follows MIME data stream rules (RFC 2046).
      // These specifications require line breaks to be represented as CRLF sequences in the canonical form.
      // See https://stackoverflow.com/questions/69835705/formdata-textarea-puts-r-carriage-return-when-sent-with-post for more details.
      const data = Object.fromEntries(formData);

      return axios({
        method: this.isEditBlob ? 'put' : 'post',
        url: this.updatePath,
        data,
      })
        .then(({ data: responseData }) => {
          if (responseData.error) {
            this.handleError(responseData.error);
            return;
          }

          if (responseData.filePath) {
            visitUrl(responseData.filePath);
            return;
          }

          this.handleError(this.errorMessage);
        })
        .catch(({ response }) => this.handleError(response?.data?.error))
        .finally(() => {
          this.isLoading = false;
        });
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
  <div class="gl-mb-4 gl-mt-5 gl-items-center gl-justify-between md:gl-flex lg:gl-my-5">
    <h1 class="gl-heading-1 gl-inline-block md:!gl-mb-0">
      {{ headerText }}
    </h1>
    <div class="gl-flex gl-gap-3">
      <gl-button
        :data-confirm="$options.i18n.confirmationMessage"
        :href="cancelPath"
        data-confirm-btn-variant="danger"
        data-testid="blob-edit-header-cancel-button"
        @click="handleCancelButtonClick"
        >{{ $options.i18n.cancelButtonText }}</gl-button
      >
      <gl-button variant="confirm" data-testid="blob-edit-header-commit-button" @click="openModal">
        {{ $options.i18n.commitButtonText }}
      </gl-button>
    </div>
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
