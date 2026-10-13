<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { refreshCurrentPageWithAlerts } from '~/lib/utils/url_utility';
import showToast from '~/vue_shared/plugins/global_toast';
import SoloOwnedGroupsList from '~/organizations/shared/components/solo_owned_groups_list.vue';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from './remove_from_organization_modal_event_hub';

const SOLO_OWNED_GROUPS_LOADING_STATUS = { loading: true, count: 0, error: false };

export default {
  name: 'RemoveOrganizationUserModal',
  components: {
    GlModal,
    GlSprintf,
    SoloOwnedGroupsList,
  },
  data() {
    return {
      username: '',
      userId: null,
      organizationUserGid: '',
      loading: false,
      soloOwnedGroups: SOLO_OWNED_GROUPS_LOADING_STATUS,
    };
  },
  computed: {
    title() {
      return sprintf(s__('AdminUsers|Remove user %{username}'), { username: this.username }, false);
    },
    hasSoloOwnedGroups() {
      return this.soloOwnedGroups.count > 0;
    },
    isRemovalBlocked() {
      return this.soloOwnedGroups.loading || this.soloOwnedGroups.error || this.hasSoloOwnedGroups;
    },
    actionPrimary() {
      return {
        text: s__('AdminUsers|Remove user'),
        attributes: { variant: 'danger', loading: this.loading, disabled: this.isRemovalBlocked },
      };
    },
    actionCancel() {
      return {
        text: __('Cancel'),
        attributes: { disabled: this.loading },
      };
    },
  },
  mounted() {
    eventHub.$on(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, this.onOpenEvent);
  },
  destroyed() {
    eventHub.$off(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, this.onOpenEvent);
  },
  methods: {
    onOpenEvent({ username, userId, organizationUserGid }) {
      if (userId !== this.userId) {
        this.soloOwnedGroups = SOLO_OWNED_GROUPS_LOADING_STATUS;
      }

      this.username = username;
      this.userId = userId;
      this.organizationUserGid = organizationUserGid;
      this.$refs.modal.show();
    },
    onSoloOwnedGroupsChange(status) {
      this.soloOwnedGroups = status;
    },
    async onSubmit() {
      this.loading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: removeOrganizationUserMutation,
          variables: { id: this.organizationUserGid },
        });

        const errors = data.organizationUserDelete?.errors || [];

        if (errors.length) {
          this.$refs.modal.hide();
          showToast(errors[0]);
          this.loading = false;
          return;
        }

        refreshCurrentPageWithAlerts([
          {
            id: 'organization-user-removed',
            message: s__('AdminUsers|User was successfully removed from the organization.'),
            variant: 'success',
          },
        ]);
      } catch (error) {
        this.$refs.modal.hide();
        showToast(
          s__(
            'AdminUsers|An error occurred while removing the user from the organization. Please try again.',
          ),
        );
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="remove-from-organization-modal"
    :title="title"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    @primary.prevent="onSubmit"
  >
    <solo-owned-groups-list
      v-if="userId"
      :key="userId"
      :user-id="userId"
      :username="username"
      @change="onSoloOwnedGroupsChange"
    >
      <template #help>
        <gl-sprintf
          :message="
            s__(
              'AdminUsers|To remove %{username} from the organization, assign another owner to each group above. Their account isn\'t deleted.',
            )
          "
        >
          <template #username
            ><strong>{{ username }}</strong></template
          >
        </gl-sprintf>
      </template>
    </solo-owned-groups-list>

    <p v-if="!isRemovalBlocked">
      <gl-sprintf
        :message="
          s__(
            'AdminUsers|You are about to remove %{username} from the organization. They will also lose access to the groups and projects they are a member of within this organization.',
          )
        "
      >
        <template #username
          ><strong>{{ username }}</strong></template
        >
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
