<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { refreshCurrentPageWithAlerts } from '~/lib/utils/url_utility';
import showToast from '~/vue_shared/plugins/global_toast';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from './remove_from_organization_modal_event_hub';

export default {
  name: 'RemoveOrganizationUserModal',
  components: {
    GlModal,
    GlSprintf,
  },
  data() {
    return {
      username: '',
      organizationUserGid: '',
      loading: false,
    };
  },
  computed: {
    actionPrimary() {
      return {
        text: __('Remove'),
        attributes: { variant: 'danger', loading: this.loading },
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
    onOpenEvent({ username, organizationUserGid }) {
      this.username = username;
      this.organizationUserGid = organizationUserGid;
      this.$refs.modal.show();
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
          s__('AdminUsers|An error occurred while removing the user from the organization.'),
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
    :title="s__('AdminUsers|Remove user from the organization?')"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    @primary.prevent="onSubmit"
  >
    <p>
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
