<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|Reactivating a user will:')}</p>
  <ul>
    <li>${s__('AdminUsers|Restore user access to the account, including web, Git and API.')}</li>
  </ul>
  <p>${s__('AdminUsers|You can always deactivate their account again if needed.')}</p>
`;

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
          title: sprintf(s__('AdminUsers|Activate user %{username}?'), {
            username: this.username,
          }),
          messageHtml,
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.activate,
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
