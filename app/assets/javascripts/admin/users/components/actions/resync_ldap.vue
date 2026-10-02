<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import { I18N_USER_ACTIONS } from '../../constants';

export default {
  name: 'UsersResyncLdap',
  components: {
    GlDisclosureDropdownItem,
  },
  mixins: [glSlotsMixin],
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
          title: sprintf(s__('AdminUsers|Resync %{username} with LDAP?'), {
            username: this.username,
          }),
          message: s__(
            'AdminUsers|GitLab will recheck this user against LDAP right now and unblock them if LDAP allows it again.',
          ),
          actionCancel: {
            text: __('Cancel'),
          },
          actionPrimary: {
            text: I18N_USER_ACTIONS.resyncLdap,
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
    <template v-if="glSlots().default" #list-item>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
