<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
import { I18N_USER_ACTIONS } from '../../constants';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|When not being monitored for spam:')}</p>
  <ul>
    <li>${s__(
      'AdminUsers|The user can create issues, notes, snippets, and merge requests that appear to be spam without being blocked.',
    )}</li>
  </ul>
  <p>${s__('AdminUsers|You can untrust this user in the future.')}</p>
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
          title: sprintf(s__('AdminUsers|Stop monitoring %{username} for possible spam?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.trust,
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
