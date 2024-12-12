<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getRefMixin from '../mixins/get_ref';
import DeleteBlobModal from './delete_blob_modal.vue';
import UploadBlobModal from './upload_blob_modal.vue';

const REPLACE_BLOB_MODAL_ID = 'modal-replace-blob';

export default {
  i18n: {
    replace: __('Replace'),
    delete: __('Delete'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    UploadBlobModal,
    DeleteBlobModal,
    LockFileButton: () => import('ee_component/repository/components/lock_file_button.vue'),
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
  inject: {
    targetBranch: {
      default: '',
    },
    originalBranch: {
      default: '',
    },
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    replacePath: {
      type: String,
      required: true,
    },
    deletePath: {
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
    emptyRepo: {
      type: Boolean,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    isLocked: {
      type: Boolean,
      required: true,
    },
    canLock: {
      type: Boolean,
      required: true,
    },
    showForkSuggestion: {
      type: Boolean,
      required: true,
    },
    isUsingLfs: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    deleteModalId() {
      return uniqueId('delete-modal');
    },
    replaceCommitMessage() {
      return sprintf(__('Replace %{name}'), { name: this.name });
    },
    deleteModalCommitMessage() {
      return sprintf(__('Delete %{name}'), { name: this.name });
    },
    lockBtnTestId() {
      return this.canLock ? 'lock-button' : 'disabled-lock-button';
    },
  },
  methods: {
    showModal(modalId) {
      if (this.showForkSuggestion) {
        this.$emit('fork', 'view');
        return;
      }

      this.$refs[modalId].show();
    },
  },
  replaceBlobModalId: REPLACE_BLOB_MODAL_ID,
};
</script>

<template>
  <div>
    <gl-button-group>
      <lock-file-button
        v-if="glFeatures.fileLocks"
        :name="name"
        :path="path"
        :project-path="projectPath"
        :is-locked="isLocked"
        :can-lock="canLock"
        :data-testid="lockBtnTestId"
      />
      <gl-button data-testid="replace" @click="showModal($options.replaceBlobModalId)">
        {{ $options.i18n.replace }}
      </gl-button>
      <gl-button data-testid="delete" @click="showModal(deleteModalId)">
        {{ $options.i18n.delete }}
      </gl-button>
    </gl-button-group>
    <upload-blob-modal
      :ref="$options.replaceBlobModalId"
      :modal-id="$options.replaceBlobModalId"
      :commit-message="replaceCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :path="path"
      :replace-path="replacePath"
    />
    <delete-blob-modal
      :ref="deleteModalId"
      :delete-path="deletePath"
      :modal-id="deleteModalId"
      :commit-message="deleteModalCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :empty-repo="emptyRepo"
      :is-using-lfs="isUsingLfs"
    />
  </div>
</template>
