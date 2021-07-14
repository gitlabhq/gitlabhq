<script>
import { GlButtonGroup, GlButton, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import getRefMixin from '../mixins/get_ref';
import DeleteBlobModal from './delete_blob_modal.vue';
import UploadBlobModal from './upload_blob_modal.vue';

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
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [getRefMixin],
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
    emptyRepo: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    replaceModalId() {
      return uniqueId('replace-modal');
    },
    replaceModalTitle() {
      return sprintf(__('Replace %{name}'), { name: this.name });
    },
    deleteModalId() {
      return uniqueId('delete-modal');
    },
    deleteModalTitle() {
      return sprintf(__('Delete %{name}'), { name: this.name });
    },
  },
};
</script>

<template>
  <div class="gl-mr-3">
    <gl-button-group>
      <gl-button v-gl-modal="replaceModalId">
        {{ $options.i18n.replace }}
      </gl-button>
      <gl-button v-gl-modal="deleteModalId">
        {{ $options.i18n.delete }}
      </gl-button>
    </gl-button-group>
    <upload-blob-modal
      :modal-id="replaceModalId"
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
      :modal-id="deleteModalId"
      :modal-title="deleteModalTitle"
      :delete-path="deletePath"
      :commit-message="deleteModalTitle"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :empty-repo="emptyRepo"
    />
  </div>
</template>
