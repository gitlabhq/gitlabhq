<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
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
        method: 'delete',
        modalAttributes: {
          title: sprintf(s__('AdminUsers|Reject user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.reject,
            attributes: { variant: 'danger' },
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
