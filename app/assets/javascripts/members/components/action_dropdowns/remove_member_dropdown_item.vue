<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';

export default {
  name: 'RemoveMemberDropdownItem',
  components: { GlDisclosureDropdownItem },
  inject: ['namespace'],
  props: {
    memberId: {
      type: Number,
      required: true,
    },
    /**
     * `GroupMember` (`app/models/members/group_member.rb`)
     * or
     * `ProjectMember` (`app/models/members/project_member.rb`).
     */
    memberModelType: {
      type: String,
      required: false,
      default: null,
    },
    modalMessage: {
      type: String,
      required: true,
    },
    isAccessRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInvite: {
      type: Boolean,
      required: false,
      default: false,
    },
    userDeletionObstacles: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    preventRemoval: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    modalData() {
      return {
        isAccessRequest: this.isAccessRequest,
        isInvite: this.isInvite,
        memberPath: this.memberPath.replace(':id', this.memberId),
        memberModelType: this.memberModelType,
        message: this.modalMessage,
        userDeletionObstacles: this.userDeletionObstacles,
        preventRemoval: this.preventRemoval,
      };
    },
  },
  methods: {
    ...mapActions({
      showRemoveMemberModal(dispatch, payload) {
        return dispatch(`${this.namespace}/showRemoveMemberModal`, payload);
      },
    }),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    data-testid="delete-member-dropdown-item"
    @action="showRemoveMemberModal(modalData)"
  >
    <template #list-item>
      <span class="gl-text-red-500">
        <slot></slot>
      </span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
