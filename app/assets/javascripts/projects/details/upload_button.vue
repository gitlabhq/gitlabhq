<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import { trackFileUploadEvent } from '../upload_file_experiment_tracking';

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
    path: {
      default: '',
    },
    projectPath: {
      default: '',
    },
  },
  methods: {
    trackOpenModal() {
      trackFileUploadEvent('click_upload_modal_trigger');
    },
  },
  uploadBlobModalId: UPLOAD_BLOB_MODAL_ID,
};
</script>
<template>
  <span>
    <gl-button
      v-gl-modal="$options.uploadBlobModalId"
      icon="upload"
      data-testid="upload-file-button"
      @click="trackOpenModal"
      >{{ __('Upload File') }}</gl-button
    >
    <upload-blob-modal
      :modal-id="$options.uploadBlobModalId"
      :commit-message="__('Upload New File')"
      :target-branch="targetBranch"
      :original-branch="originalBranch"
      :can-push-code="canPushCode"
      :path="path"
    />
  </span>
</template>
