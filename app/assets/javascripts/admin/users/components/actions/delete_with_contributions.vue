<script>
import { GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { associationsCount } from '~/api/user_api';
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

      const associationsCountErrorId = 'associationsCountError';

      try {
        const organizations = await getSoloOwnedOrganizations(
          this.$apollo.provider.defaultClient,
          this.userId,
        );

        if (organizations.count > 0) {
          this.openModal({ organizations });

          return;
        }

        const { data: associationsCountData } = await associationsCount(this.userId).catch(
          (error) => {
            // eslint-disable-next-line no-param-reassign
            error.id = associationsCountErrorId;
            throw error;
          },
        );

        this.openModal({ associationsCountData, organizations });
      } catch (error) {
        if (error.id === associationsCountErrorId) {
          this.openModal({ associationsCountData: new Error() });
        } else {
          this.openModal({ organizations: SOLO_OWNED_ORGANIZATIONS_EMPTY });
        }
      } finally {
        this.loading = false;
      }
    },
    openModal({ associationsCountData, organizations }) {
      const { username, paths, userDeletionObstacles } = this;
      eventHub.$emit(EVENT_OPEN_DELETE_USER_MODAL, {
        username,
        blockPath: paths.block,
        deletePath: paths.deleteWithContributions,
        userDeletionObstacles,
        associationsCount: associationsCountData,
        organizations,
        i18n: {
          title: s__('AdminUsers|Delete User %{username} and contributions?'),
          primaryButtonLabel: s__('AdminUsers|Delete user and contributions'),
          messageBody:
            s__(`AdminUsers|You are about to permanently delete the user %{username}. This will delete all issues,
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
