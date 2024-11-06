<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { getSoloOwnedOrganizations } from '~/admin/users/utils';
import { SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import eventHub, { EVENT_OPEN_DELETE_USER_MODAL } from '../modals/delete_user_modal_event_hub';

export default {
  i18n: {
    loading: __('Loading'),
  },
  components: {
    GlDisclosureDropdownItem,
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
        const organizations = await getSoloOwnedOrganizations(
          this.$apollo.provider.defaultClient,
          this.userId,
        );

        this.openModal(organizations);
      } catch (error) {
        this.openModal(SOLO_OWNED_ORGANIZATIONS_EMPTY);
      } finally {
        this.loading = false;
      }
    },
    openModal(organizations) {
      const { username, paths, userDeletionObstacles } = this;
      eventHub.$emit(EVENT_OPEN_DELETE_USER_MODAL, {
        username,
        blockPath: paths.block,
        deletePath: paths.delete,
        userDeletionObstacles,
        organizations,
        i18n: {
          title: s__('AdminUsers|Delete User %{username}?'),
          primaryButtonLabel: s__('AdminUsers|Delete user'),
          messageBody:
            s__(`AdminUsers|You are about to permanently delete the user %{username}. Issues, merge requests,
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
  <gl-disclosure-dropdown-item :disabled="loading" :aria-busy="loading" @action="onClick">
    <template #list-item>
      <div v-if="loading" class="gl-flex gl-items-center">
        <gl-loading-icon class="gl-mr-3" />
        {{ $options.i18n.loading }}
      </div>
      <span v-else class="gl-text-red-500">
        <slot></slot>
      </span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
