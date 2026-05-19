<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { buildDuplicateUrl } from '../utils';

export default {
  name: 'PersonalAccessTokenDuplicateModal',
  components: {
    GlModal,
    GlSprintf,
  },
  inject: ['accessTokenGranularNewUrl'],
  props: {
    token: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['cancel'],
  computed: {
    isModalVisible() {
      return Boolean(this.token);
    },
    modalTitle() {
      if (!this.token) {
        return '';
      }

      return sprintf(this.$options.i18n.title, { tokenName: this.token.name }, false);
    },
    actionPrimary() {
      return { text: this.$options.i18n.duplicate, attributes: { variant: 'confirm' } };
    },
    actionCancel() {
      return { text: this.$options.i18n.cancel };
    },
  },
  methods: {
    handleConfirm() {
      if (!this.token) return;
      window.location.href = buildDuplicateUrl(this.token, this.accessTokenGranularNewUrl);
    },
    handleCancel() {
      this.$emit('cancel');
    },
  },
  i18n: {
    title: s__("AccessTokens|Duplicate '%{tokenName}'?"),
    description: s__(
      'AccessTokens|A new fine-grained token form will open with the resource and permissions from %{tokenName} pre-filled. %{tokenName} will not be affected.',
    ),
    duplicate: s__('AccessTokens|Duplicate'),
    cancel: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    :visible="isModalVisible"
    :title="modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    modal-id="duplicate-token-modal"
    @primary="handleConfirm"
    @hidden="handleCancel"
  >
    <p v-if="token">
      <gl-sprintf :message="$options.i18n.description">
        <template #tokenName>
          <b>{{ token.name }}</b>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
