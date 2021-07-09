<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|Approved users can:')}</p>
  <ul>
    <li>${s__('AdminUsers|Log in')}</li>
    <li>${s__('AdminUsers|Access Git repositories')}</li>
    <li>${s__('AdminUsers|Access the API')}</li>
    <li>${s__('AdminUsers|Be added to groups and projects')}</li>
  </ul>
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
    attributes() {
      return {
        'data-path': this.path,
        'data-method': 'put',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Approve user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.approve,
            attributes: [{ variant: 'confirm', 'data-qa-selector': 'approve_user_confirm_button' }],
          },
          messageHtml,
        }),
        'data-qa-selector': 'approve_user_button',
      };
    },
  },
};
</script>

<template>
  <gl-dropdown-item button-class="js-confirm-modal-button" v-bind="{ ...attributes }">
    <slot></slot>
  </gl-dropdown-item>
</template>
