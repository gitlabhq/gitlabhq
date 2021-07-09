<script>
import { GlDropdownItem } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf, s__, __ } from '~/locale';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|When banned, users:')}</p>
  <ul>
    <li>${s__("AdminUsers|Can't log in.")}</li>
    <li>${s__("AdminUsers|Can't access Git repositories.")}</li>
  </ul>
  <p>${s__('AdminUsers|You can unban their account in the future. Their data remains intact.')}</p>
  <p>${sprintf(
    s__('AdminUsers|Learn more about %{link_start}banned users.%{link_end}'),
    {
      link_start: `<a href="${helpPagePath('user/admin_area/moderate_users', {
        anchor: 'ban-a-user',
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
        'data-method': 'put',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Ban user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.ban,
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
