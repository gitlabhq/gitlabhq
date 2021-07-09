<script>
import { GlDropdownItem } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|Rejected users:')}</p>
  <ul>
    <li>${s__('AdminUsers|Cannot sign in or access instance information')}</li>
    <li>${s__('AdminUsers|Will be deleted')}</li>
  </ul>
  <p>${sprintf(
    s__(
      'AdminUsers|For more information, please refer to the %{link_start}user account deletion documentation.%{link_end}',
    ),
    {
      link_start: `<a href="${helpPagePath('user/profile/account/delete_account', {
        anchor: 'associated-records',
      })}" target="_blank">`,
      link_end: '</a>',
    },
    false,
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
        'data-method': 'delete',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Reject user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.reject,
            attributes: [{ variant: 'danger' }],
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
