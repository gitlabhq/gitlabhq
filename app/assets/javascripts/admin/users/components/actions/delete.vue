<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub, { EVENT_OPEN_DELETE_USER_MODAL } from '../modals/delete_user_modal_event_hub';

export default {
  components: {
    GlDisclosureDropdownItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    userId: {
      type: Number,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    },
    userDeletionObstacles: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    onClick() {
      const { username, paths, userDeletionObstacles } = this;
      eventHub.$emit(EVENT_OPEN_DELETE_USER_MODAL, {
        username,
        blockPath: paths.block,
        deletePath: paths.delete,
        userDeletionObstacles,
        i18n: {
          title: s__('AdminUsers|Delete User %{username}?'),
          primaryButtonLabel: s__('AdminUsers|Delete user'),
          messageBody: s__(`AdminUsers|You are about to permanently delete the user %{username}. Issues, merge requests,
                            and groups linked to them will be transferred to a system-wide "Ghost-user". To avoid data loss,
                            consider using the %{strongStart}block user%{strongEnd} feature instead. Once you %{strongStart}Delete user%{strongEnd},
                            it cannot be undone or recovered.`),
        },
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item @action="onClick">
    <template #list-item>
      <span class="gl-text-red-500">
        <slot></slot>
      </span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
