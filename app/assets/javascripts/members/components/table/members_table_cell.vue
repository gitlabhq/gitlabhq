<script>
import { MEMBERS_TAB_TYPES } from 'ee_else_ce/members/constants';
import {
  isGroup,
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
        return MEMBERS_TAB_TYPES.group;
      }
      if (this.isInvite) {
        return MEMBERS_TAB_TYPES.invite;
      }
      if (this.isAccessRequest) {
        return MEMBERS_TAB_TYPES.accessRequest;
      }

      return MEMBERS_TAB_TYPES.user;
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
