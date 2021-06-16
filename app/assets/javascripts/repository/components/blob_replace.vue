<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import getRefMixin from '../mixins/get_ref';
import UploadBlobModal from './upload_blob_modal.vue';

export default {
  i18n: {
    replace: __('Replace'),
    replacePrimaryBtnText: __('Replace file'),
  },
  components: {
    GlButton,
    UploadBlobModal,
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
    canPushCode: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    replaceModalId() {
      return uniqueId('replace-modal');
    },
    title() {
      return sprintf(__('Replace %{name}'), { name: this.name });
    },
  },
};
</script>

<template>
  <div class="gl-mr-3">
    <gl-button v-gl-modal="replaceModalId">
      {{ $options.i18n.replace }}
    </gl-button>
    <upload-blob-modal
      :modal-id="replaceModalId"
      :modal-title="title"
      :commit-message="title"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="canPushCode"
      :path="path"
      :replace-path="replacePath"
      :primary-btn-text="$options.i18n.replacePrimaryBtnText"
    />
  </div>
</template>
