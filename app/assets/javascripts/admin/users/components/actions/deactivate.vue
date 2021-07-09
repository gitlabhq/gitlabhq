<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|Deactivating a user has the following effects:')}</p>
  <ul>
    <li>${s__('AdminUsers|The user will be logged out')}</li>
    <li>${s__('AdminUsers|The user will not be able to access git repositories')}</li>
    <li>${s__('AdminUsers|The user will not be able to access the API')}</li>
    <li>${s__('AdminUsers|The user will not receive any notifications')}</li>
    <li>${s__('AdminUsers|The user will not be able to use slash commands')}</li>
    <li>${s__(
      'AdminUsers|When the user logs back in, their account will reactivate as a fully active account',
    )}</li>
    <li>${s__('AdminUsers|Personal projects, group and user history will be left intact')}</li>
  </ul>
  <p>${s__(
    'AdminUsers|You can always re-activate their account, their data will remain intact.',
  )}</p>
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
          title: sprintf(s__('AdminUsers|Deactivate user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.deactivate,
            attributes: [{ variant: 'confirm' }],
          },
          messageHtml,
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
