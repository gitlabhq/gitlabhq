<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const UPLOAD_BLOB_MODAL_ID = 'details-modal-upload-blob';

export default {
  components: {
    GlButton,
    UploadBlobModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    targetBranch: {
      default: '',
    },
    originalBranch: {
      default: '',
    },
    canPushCode: {
      default: false,
    },
    canPushToBranch: {
      default: false,
    },
    path: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    emptyRepo: {
      default: false,
    },
  },
  uploadBlobModalId: UPLOAD_BLOB_MODAL_ID,
};
</script>
<template>
  <span>
    <gl-button
      v-gl-modal="$options.uploadBlobModalId"
      variant="link"
      icon="upload"
      class="stat-link !gl-px-0"
      button-text-classes="gl-ml-2"
      data-testid="upload-file-button"
      >{{ __('Upload File') }}</gl-button
    >
    <upload-blob-modal
      :modal-id="$options.uploadBlobModalId"
      :commit-message="__('Upload New File')"
      :target-branch="targetBranch"
      :original-branch="originalBranch"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :path="path"
      :empty-repo="emptyRepo"
    />
  </span>
</template>
