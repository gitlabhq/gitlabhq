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
    origionalBranch: {
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
  uploadBlobModalId: UPLOAD_BLOB_MODAL_ID,
};
</script>
<template>
  <span>
    <gl-button v-gl-modal="$options.uploadBlobModalId" icon="upload">{{
      __('Upload File')
    }}</gl-button>
    <upload-blob-modal
      :modal-id="$options.uploadBlobModalId"
      :commit-message="__('Upload New File')"
      :target-branch="targetBranch"
      :origional-branch="origionalBranch"
      :can-push-code="canPushCode"
      :path="path"
    />
  </span>
</template>
