<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalAttributes() {
      return {
        'data-path': this.path,
        'data-method': 'put',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Unlock user %{username}?'), { username: this.username }),
          message: __('Are you sure?'),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.unlock,
            attributes: [{ variant: 'confirm' }],
          },
        }),
      };
    },
  },
};
</script>

<template>
  <gl-dropdown-item button-class="js-confirm-modal-button" v-bind="{ ...modalAttributes }">
    <slot></slot>
  </gl-dropdown-item>
</template>
