<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from '../modals/remove_from_organization_modal_event_hub';

export default {
  name: 'UsersRemoveFromOrganization',
  components: {
    GlDisclosureDropdownItem,
  },
  mixins: [glSlotsMixin],
  inheritAttrs: false,
  props: {
    username: {
      type: String,
      required: true,
    },
    organizationUserGid: {
      type: String,
      required: true,
    },
  },
  methods: {
    onClick() {
      eventHub.$emit(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
        username: this.username,
        organizationUserGid: this.organizationUserGid,
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item variant="danger" @action="onClick">
    <template v-if="glSlots().default" #list-item>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
