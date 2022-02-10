<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  btnText: __('Fork project'),
  title: __('Fork project?'),
  message: __(
    'You can’t edit files directly in this project. Fork this project and submit a merge request with your changes.',
  ),
};

export default {
  name: 'ConfirmForkModal',
  components: {
    GlModal,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    forkPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    btnActions() {
      return {
        cancel: { text: __('Cancel') },
        primary: {
          text: this.$options.i18n.btnText,
          attributes: {
            href: this.forkPath,
            variant: 'confirm',
            'data-qa-selector': 'fork_project_button',
            'data-method': 'post',
          },
        },
      };
    },
  },
  i18n,
};
</script>
<template>
  <gl-modal
    :visible="visible"
    data-qa-selector="confirm_fork_modal"
    :modal-id="modalId"
    :title="$options.i18n.title"
    :action-primary="btnActions.primary"
    :action-cancel="btnActions.cancel"
    @change="$emit('change', $event)"
  >
    <p>{{ $options.i18n.message }}</p>
  </gl-modal>
</template>
