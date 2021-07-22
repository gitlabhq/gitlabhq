<script>
import { GlFormCheckbox, GlModal } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { s__, __ } from '~/locale';
import OncallSchedulesList from '~/vue_shared/components/oncall_schedules_list.vue';

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  csrf,
  components: {
    GlFormCheckbox,
    GlModal,
    OncallSchedulesList,
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
      memberType(state) {
        return state[this.namespace].removeMemberModalData.memberType;
      },
      message(state) {
        return state[this.namespace].removeMemberModalData.message;
      },
      oncallSchedules(state) {
        return state[this.namespace].removeMemberModalData.oncallSchedules ?? {};
      },
      removeMemberModalVisible(state) {
        return state[this.namespace].removeMemberModalVisible;
      },
    }),
    isGroupMember() {
      return this.memberType === 'GroupMember';
    },
    actionText() {
      if (this.isAccessRequest) {
        return __('Deny access request');
      } else if (this.isInvite) {
        return s__('Member|Revoke invite');
      }

      return __('Remove member');
    },
    actionPrimary() {
      return {
        text: this.actionText,
        attributes: {
          variant: 'danger',
        },
      };
    },
    showUnassignIssuablesCheckbox() {
      return !this.isAccessRequest && !this.isInvite;
    },
    isPartOfOncallSchedules() {
      return !this.isAccessRequest && this.oncallSchedules.schedules?.length;
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
    data-qa-selector="remove_member_modal_content"
    @primary="submitForm"
    @hide="hideRemoveMemberModal"
  >
    <form ref="form" :action="memberPath" method="post">
      <p>{{ message }}</p>

      <oncall-schedules-list
        v-if="isPartOfOncallSchedules"
        :schedules="oncallSchedules.schedules"
        :user-name="oncallSchedules.name"
      />

      <input ref="method" type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <gl-form-checkbox v-if="isGroupMember" name="remove_sub_memberships">
        {{ __('Also remove direct user membership from subgroups and projects') }}
      </gl-form-checkbox>
      <gl-form-checkbox v-if="showUnassignIssuablesCheckbox" name="unassign_issuables">
        {{ __('Also unassign this user from related issues and merge requests') }}
      </gl-form-checkbox>
    </form>
  </gl-modal>
</template>
