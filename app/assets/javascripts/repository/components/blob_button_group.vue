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
    replacePrimaryBtnText: __('Replace file'),
    delete: __('Delete'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    UploadBlobModal,
    DeleteBlobModal,
    LockButton: () => import('ee_component/repository/components/lock_button.vue'),
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
  },
  computed: {
    replaceModalTitle() {
      return sprintf(__('Replace %{name}'), { name: this.name });
    },
    deleteModalId() {
      return uniqueId('delete-modal');
    },
    deleteModalTitle() {
      return sprintf(__('Delete %{name}'), { name: this.name });
    },
    lockBtnQASelector() {
      return this.canLock ? 'lock_button' : 'disabled_lock_button';
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
  <div class="gl-mr-3">
    <gl-button-group>
      <lock-button
        v-if="glFeatures.fileLocks"
        :name="name"
        :path="path"
        :project-path="projectPath"
        :is-locked="isLocked"
        :can-lock="canLock"
        data-testid="lock"
        :data-qa-selector="lockBtnQASelector"
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
      :modal-title="replaceModalTitle"
      :commit-message="replaceModalTitle"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :path="path"
      :replace-path="replacePath"
      :primary-btn-text="$options.i18n.replacePrimaryBtnText"
    />
    <delete-blob-modal
      :ref="deleteModalId"
      :modal-id="deleteModalId"
      :modal-title="deleteModalTitle"
      :delete-path="deletePath"
      :commit-message="deleteModalTitle"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :empty-repo="emptyRepo"
    />
  </div>
</template>
