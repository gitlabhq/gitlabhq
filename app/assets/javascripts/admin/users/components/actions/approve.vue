<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
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
    GlDisclosureDropdownItem,
  },
  inject: {
    isAtSeatsLimit: { default: false },
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
      const modalProps = {
        path: this.path,
        method: 'put',
        modalAttributes: {
          errorAlertMessage: this.isAtSeatsLimit
            ? s__(
                'AdminUsers|There are no more seats left in your subscription. New users cannot be approved for this instance.',
              )
            : null,
          title: sprintf(s__('AdminUsers|Approve user %{username}?'), {
            username: this.username,
          }),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.approve,
            attributes: {
              variant: 'confirm',
              disabled: this.isAtSeatsLimit,
              'data-testid': 'approve-user-confirm-button',
            },
          },
          messageHtml,
        },
      };

      eventHub.$emit(EVENT_OPEN_CONFIRM_MODAL, modalProps);
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
