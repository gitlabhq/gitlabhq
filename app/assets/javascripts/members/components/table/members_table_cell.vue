<script>
import { MEMBER_TYPES } from 'ee_else_ce/members/constants';
import {
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canRemoveBlockedByLastOwner,
  canResend,
  canUpdate,
} from '../../utils';

export default {
  name: 'MembersTableCell',
  inject: ['currentUserId', 'canManageMembers'],
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isGroup() {
      return isGroup(this.member);
    },
    isInvite() {
      return Boolean(this.member.invite);
    },
    isAccessRequest() {
      return Boolean(this.member.requestedAt);
    },
    memberType() {
      if (this.isGroup) {
        return MEMBER_TYPES.group;
      }
      if (this.isInvite) {
        return MEMBER_TYPES.invite;
      }
      if (this.isAccessRequest) {
        return MEMBER_TYPES.accessRequest;
      }

      return MEMBER_TYPES.user;
    },
    isDirectMember() {
      return isDirectMember(this.member);
    },
    isCurrentUser() {
      return isCurrentUser(this.member, this.currentUserId);
    },
    canRemoveBlockedByLastOwner() {
      return canRemoveBlockedByLastOwner(this.member, this.canManageMembers);
    },
    canRemove() {
      return canRemove(this.member);
    },
    canResend() {
      return canResend(this.member);
    },
    canUpdate() {
      return canUpdate(this.member, this.currentUserId);
    },
  },
  render() {
    return this.$scopedSlots.default({
      memberType: this.memberType,
      isDirectMember: this.isDirectMember,
      isCurrentUser: this.isCurrentUser,
      permissions: {
        canRemove: this.canRemove,
        canRemoveBlockedByLastOwner: this.canRemoveBlockedByLastOwner,
        canResend: this.canResend,
        canUpdate: this.canUpdate,
      },
    });
  },
};
</script>
