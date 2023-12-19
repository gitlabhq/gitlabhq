<script>
import { GlFormCheckbox, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { s__, __ } from '~/locale';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import { MEMBER_MODEL_TYPE_GROUP_MEMBER } from '../../constants';

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  csrf,
  components: {
    GlFormCheckbox,
    GlModal,
    UserDeletionObstaclesList,
  },
  inject: ['namespace'],
  computed: {
    ...mapState({
      isAccessRequest(state) {
        return state[this.namespace].removeMemberModalData.isAccessRequest;
      },
      isInvite(state) {
        return state[this.namespace].removeMemberModalData.isInvite;
      },
      memberPath(state) {
        return state[this.namespace].removeMemberModalData.memberPath;
      },
      /**
       * `GroupMember` (`app/models/members/group_member.rb`)
       * or
       * `ProjectMember` (`app/models/members/project_member.rb`).
       */
      memberModelType(state) {
        return state[this.namespace].removeMemberModalData.memberModelType;
      },
      message(state) {
        return state[this.namespace].removeMemberModalData.message;
      },
      userDeletionObstacles(state) {
        return state[this.namespace].removeMemberModalData.userDeletionObstacles ?? {};
      },
      preventRemoval(state) {
        return state[this.namespace].removeMemberModalData.preventRemoval;
      },
      removeMemberModalVisible(state) {
        return state[this.namespace].removeMemberModalVisible;
      },
    }),
    isGroupMember() {
      return this.memberModelType === MEMBER_MODEL_TYPE_GROUP_MEMBER;
    },
    actionText() {
      if (this.isAccessRequest) {
        return __('Deny access request');
      }
      if (this.isInvite) {
        return s__('Member|Revoke invite');
      }

      return __('Remove member');
    },
    actionPrimary() {
      if (this.preventRemoval) {
        return null;
      }

      return {
        text: this.actionText,
        attributes: {
          variant: 'danger',
          'data-testid': 'remove-member-button',
        },
      };
    },
    hasWorkspaceAccess() {
      return !this.isAccessRequest && !this.isInvite;
    },
    hasObstaclesToUserDeletion() {
      return this.hasWorkspaceAccess && this.userDeletionObstacles.obstacles?.length;
    },
  },
  methods: {
    ...mapActions({
      hideRemoveMemberModal(dispatch) {
        return dispatch(`${this.namespace}/hideRemoveMemberModal`);
      },
    }),
    submitForm() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="remove-member-modal"
    :action-cancel="$options.actionCancel"
    :action-primary="actionPrimary"
    :title="actionText"
    :visible="removeMemberModalVisible"
    data-testid="remove-member-modal"
    @primary="submitForm"
    @hide="hideRemoveMemberModal"
  >
    <form ref="form" :action="memberPath" method="post">
      <p>{{ message }}</p>
      <template v-if="!preventRemoval">
        <user-deletion-obstacles-list
          v-if="hasObstaclesToUserDeletion"
          :obstacles="userDeletionObstacles.obstacles"
          :user-name="userDeletionObstacles.name"
        />

        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
        <gl-form-checkbox v-if="isGroupMember" name="remove_sub_memberships">
          {{ __('Also remove direct user membership from subgroups and projects') }}
        </gl-form-checkbox>
        <gl-form-checkbox v-if="hasWorkspaceAccess" name="unassign_issuables">
          {{ __('Also unassign this user from related issues and merge requests') }}
        </gl-form-checkbox>
      </template>
    </form>
  </gl-modal>
</template>
