<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|When banned:')}</p>
  <ul>
    <li>${s__("AdminUsers|The user can't log in.")}</li>
    <li>${s__("AdminUsers|The user can't access git repositories.")}</li>
    <li>${s__(
      'AdminUsers|Projects, issues, merge requests, and comments of this user are hidden from other users.',
    )}</li>
  </ul>
  <p>${s__('AdminUsers|You can unban their account in the future. Their data remains intact.')}</p>
  <p>${sprintf(
    s__('AdminUsers|Learn more about %{link_start}banned users.%{link_end}'),
    {
      link_start: `<a href="${helpPagePath('administration/moderate_users', {
        anchor: 'ban-a-user',
      })}" target="_blank">`,
      link_end: '</a>',
    },
    false,
  )}</p>
`;

export default {
  components: {
    GlDisclosureDropdownItem,
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
  methods: {
    onClick() {
      eventHub.$emit(EVENT_OPEN_CONFIRM_MODAL, {
        path: this.path,
        method: 'put',
        modalAttributes: {
          title: sprintf(s__('AdminUsers|Ban user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.ban,
            attributes: { variant: 'confirm' },
          },
          messageHtml,
        },
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item @action="onClick">
    <template #list-item>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
