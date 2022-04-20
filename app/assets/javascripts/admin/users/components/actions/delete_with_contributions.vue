<script>
import { GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub, { EVENT_OPEN_DELETE_USER_MODAL } from '../modals/delete_user_modal_event_hub';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    username: {
      type: String,
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
        deletePath: paths.deleteWithContributions,
        userDeletionObstacles,
        i18n: {
          title: s__('AdminUsers|Delete User %{username} and contributions?'),
          primaryButtonLabel: s__('AdminUsers|Delete user and contributions'),
          messageBody: s__(`AdminUsers|You are about to permanently delete the user %{username}. This will delete all of the issues,
                            merge requests, and groups linked to them. To avoid data loss,
                            consider using the %{strongStart}block user%{strongEnd} feature instead. Once you %{strongStart}Delete user%{strongEnd},
                            it cannot be undone or recovered.`),
        },
      });
    },
  },
};
</script>

<template>
  <gl-dropdown-item @click="onClick">
    <span class="gl-text-red-500">
      <slot></slot>
    </span>
  </gl-dropdown-item>
</template>
