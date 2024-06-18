<script>
import { s__, sprintf } from '~/locale';
import ActionButtonGroup from './action_button_group.vue';
import ApproveAccessRequestButton from './approve_access_request_button.vue';
import RemoveMemberButton from './remove_member_button.vue';

export default {
  name: 'AccessRequestActionButtons',
  components: { ActionButtonGroup, RemoveMemberButton, ApproveAccessRequestButton },
  inject: ['canApproveAccessRequests'],
  inheritAttrs: false,
  props: {
    member: {
      type: Object,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    message() {
      const { user, source } = this.member;

      if (this.isCurrentUser) {
        return sprintf(
          s__('Members|Are you sure you want to withdraw your access request for "%{source}"'),
          { source: source.fullName },
        );
      }

      return sprintf(
        s__('Members|Are you sure you want to deny %{usersName}\'s request to join "%{source}"'),
        { usersName: user.name, source: source.fullName },
      );
    },
  },
};
</script>

<template>
  <action-button-group>
    <div v-if="canApproveAccessRequests" class="gl-px-1">
      <approve-access-request-button :member-id="member.id" />
    </div>
    <div class="gl-px-1">
      <remove-member-button
        :member-id="member.id"
        :message="message"
        :title="s__('Member|Deny access')"
        :is-access-request="true"
      />
    </div>
  </action-button-group>
</template>
