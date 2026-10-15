<script>
import { GlModal } from '@gitlab/ui';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { rootPath } from '~/lib/utils/path_helpers/routes';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import SoloOwnedGroupsList from '~/organizations/shared/components/solo_owned_groups_list.vue';
import organizationUserDeleteMutation from '../graphql/mutations/organization_user_delete.mutation.graphql';

export default {
  name: 'LeaveOrganizationModal',
  components: {
    GlModal,
    SoloOwnedGroupsList,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    organization: {
      type: Object,
      required: true,
    },
    organizationUserGid: {
      type: String,
      required: true,
    },
  },
  emits: ['change'],
  data() {
    return {
      isLoading: false,
      soloOwnedGroups: { loading: true, count: 0, error: false },
    };
  },
  modal: {
    actionCancel: { text: __('Cancel') },
  },
  computed: {
    title() {
      return sprintf(s__('Organization|Are you sure you want to leave "%{name}"?'), {
        name: this.organization.name,
      });
    },
    currentUserId() {
      return window.gon.current_user_id;
    },
    hasSoloOwnedGroups() {
      return this.soloOwnedGroups.count > 0;
    },
    isLeaveBlocked() {
      return this.soloOwnedGroups.loading || this.soloOwnedGroups.error || this.hasSoloOwnedGroups;
    },
    actionPrimary() {
      return {
        text: s__('Organization|Leave organization'),
        attributes: {
          variant: 'danger',
          loading: this.isLoading,
          disabled: this.isLeaveBlocked,
        },
      };
    },
  },
  methods: {
    onSoloOwnedGroupsChange(status) {
      this.soloOwnedGroups = status;
    },
    async handlePrimary() {
      this.isLoading = true;

      try {
        const {
          data: {
            organizationUserDelete: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUserDeleteMutation,
          variables: {
            input: {
              id: this.organizationUserGid,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }

        visitUrlWithAlerts(rootPath({ organizationPath: null }), [
          {
            id: 'organization-left-successfully',
            message: sprintf(s__('Organization|You left the "%{name}" organization.'), {
              name: this.organization.name,
            }),
            variant: 'info',
          },
        ]);
      } catch (error) {
        this.$emit('change', false);
        createAlert({
          message: s__(
            'Organization|An error occurred while leaving the organization. Please try again.',
          ),
          error,
          captureError: true,
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$options.modal"
    :modal-id="modalId"
    :visible="visible"
    :title="title"
    :action-primary="actionPrimary"
    @primary.prevent="handlePrimary"
    @change="$emit('change', $event)"
  >
    <solo-owned-groups-list :user-id="currentUserId" @change="onSoloOwnedGroupsChange">
      <template #help>
        {{
          s__(
            "Organization|To leave the organization, assign another owner to each group above. Your account isn't deleted.",
          )
        }}
      </template>
    </solo-owned-groups-list>

    <template v-if="!isLeaveBlocked">
      <p>{{ s__('Organization|When you leave this organization:') }}</p>
      <ul>
        <li>{{ s__('Organization|You lose access to all its groups and projects') }}</li>
        <li>
          {{
            s__(
              'Organization|An Organization administrator must add you back to restore your access',
            )
          }}
        </li>
      </ul>
    </template>
  </gl-modal>
</template>
