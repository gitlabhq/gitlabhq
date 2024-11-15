<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import getRefMixin from '../mixins/get_ref';

export default {
  components: {
    CommitChangesModal,
    GlButton,
  },
  mixins: [getRefMixin],
  inject: [
    'editor',
    'updatePath',
    'cancelPath',
    'originalBranch',
    'targetBranch',
    'blobName',
    'canPushCode',
    'canPushToBranch',
    'emptyRepo',
    'isUsingLfs',
    'branchAllowsCollaboration',
    'lastCommitSha',
  ],
  data() {
    return {
      isCommitChangeModalOpen: false,
      fileContent: null,
      filePath: null,
    };
  },
  computed: {
    updateModalId() {
      return uniqueId('update-modal');
    },
    updateModalCommitMessage() {
      return sprintf(__('Edit %{name}'), { name: this.blobName });
    },
  },
  methods: {
    handleCancelButtonClick() {
      window.onbeforeunload = null;
    },
    openModal() {
      this.fileContent = this.editor.getFileContent();
      this.filePath = this.editor.filepathFormMediator?.$filenameInput?.val();
      this.$refs[this.updateModalId].show();
    },
  },
  i18n: {
    headerText: __('Edit file'),
    cancelButtonText: __('Cancel'),
    commitButtonText: __('Commit changes'),
    confirmationMessage: __('Leave edit mode? All unsaved changes will be lost.'),
  },
};
</script>

<template>
  <div class="gl-mb-4 gl-mt-5 gl-items-center gl-justify-between md:gl-flex lg:gl-my-5">
    <h1 class="gl-heading-1 gl-inline-block md:!gl-mb-0">
      {{ $options.i18n.headerText }}
    </h1>
    <div class="gl-flex gl-gap-3">
      <gl-button
        :data-confirm="$options.i18n.confirmationMessage"
        data-confirm-btn-variant="danger"
        :href="cancelPath"
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
      :action-path="updatePath"
      :commit-message="updateModalCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :empty-repo="emptyRepo"
      :can-push-to-branch="canPushToBranch"
      :is-using-lfs="isUsingLfs"
      :file-content="fileContent"
      :file-path="filePath"
      :branch-allows-collaboration="branchAllowsCollaboration"
      :last-commit-sha="lastCommitSha"
      method="put"
      is-edit
    />
  </div>
</template>
