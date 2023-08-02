<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
import { I18N_USER_ACTIONS } from '../../constants';

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
          title: sprintf(s__('AdminUsers|Unlock user %{username}?'), { username: this.username }),
          message: __('Are you sure?'),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.unlock,
            attributes: { variant: 'confirm' },
          },
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
