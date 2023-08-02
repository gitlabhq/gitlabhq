<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
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
          title: sprintf(s__('AdminUsers|Deactivate user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.deactivate,
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
