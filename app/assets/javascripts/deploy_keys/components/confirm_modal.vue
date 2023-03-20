<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    body: __(
      'Are you sure you want to remove this deploy key? If anything is still using this key, it will stop working.',
    ),
  },
  modalOptions: {
    title: __('Do you want to remove this deploy key?'),
    actionPrimary: {
      text: __('Remove deploy key'),
      attributes: { variant: 'danger' },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: { category: 'tertiary' },
    },
    static: true,
    modalId: 'confirm-remove-deploy-key',
  },
};
</script>
<template>
  <gl-modal
    v-bind="$options.modalOptions"
    :visible="visible"
    @primary="$emit('remove')"
    @secondary="$emit('cancel')"
    @hidden="$emit('cancel')"
  >
    {{ $options.i18n.body }}
  </gl-modal>
</template>
