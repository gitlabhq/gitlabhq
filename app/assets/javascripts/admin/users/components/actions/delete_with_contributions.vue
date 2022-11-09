<script>
import { GlDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { associationsCount } from '~/api/user_api';
import eventHub, { EVENT_OPEN_DELETE_USER_MODAL } from '../modals/delete_user_modal_event_hub';

export default {
  i18n: {
    loading: __('Loading'),
  },
  components: {
    GlDropdownItem,
    GlLoadingIcon,
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
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async onClick() {
      this.loading = true;
      try {
        const { data: associationsCountData } = await associationsCount(this.userId);
        this.openModal(associationsCountData);
      } catch (error) {
        this.openModal(new Error());
      } finally {
        this.loading = false;
      }
    },
    openModal(associationsCountData) {
      const { username, paths, userDeletionObstacles } = this;
      eventHub.$emit(EVENT_OPEN_DELETE_USER_MODAL, {
        username,
        blockPath: paths.block,
        deletePath: paths.deleteWithContributions,
        userDeletionObstacles,
        associationsCount: associationsCountData,
        i18n: {
          title: s__('AdminUsers|Delete User %{username} and contributions?'),
          primaryButtonLabel: s__('AdminUsers|Delete user and contributions'),
          messageBody: s__(`AdminUsers|You are about to permanently delete the user %{username}. This will delete all issues,
                            merge requests, groups, and projects linked to them. To avoid data loss,
                            consider using the %{strongStart}Block user%{strongEnd} feature instead. After you %{strongStart}Delete user%{strongEnd},
                            you cannot undo this action or recover the data.`),
        },
      });
    },
  },
};
</script>

<template>
  <gl-dropdown-item :disabled="loading" :aria-busy="loading" @click.capture.native.stop="onClick">
    <div v-if="loading" class="gl-display-flex gl-align-items-center">
      <gl-loading-icon class="gl-mr-3" />
      {{ $options.i18n.loading }}
    </div>
    <span v-else class="gl-text-red-500">
      <slot></slot>
    </span>
  </gl-dropdown-item>
</template>
