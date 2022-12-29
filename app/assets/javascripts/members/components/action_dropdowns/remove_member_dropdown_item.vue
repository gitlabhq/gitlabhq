<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

export default {
  name: 'RemoveMemberDropdownItem',
  components: { GlDropdownItem },
  inject: ['namespace'],
  props: {
    memberId: {
      type: Number,
      required: true,
    },
    memberType: {
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
        memberType: this.memberType,
        message: this.modalMessage,
        userDeletionObstacles: this.userDeletionObstacles,
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
  <gl-dropdown-item
    data-qa-selector="delete_member_dropdown_item"
    @click="showRemoveMemberModal(modalData)"
  >
    <span class="gl-text-red-500">
      <slot></slot>
    </span>
  </gl-dropdown-item>
</template>
