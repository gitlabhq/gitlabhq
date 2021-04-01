<script>
import { MEMBER_TYPES } from '../../constants';
import {
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canResend,
  canUpdate,
} from '../../utils';

export default {
  name: 'MembersTableCell',
  inject: ['currentUserId'],
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
      } else if (this.isInvite) {
        return MEMBER_TYPES.invite;
      } else if (this.isAccessRequest) {
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
        canResend: this.canResend,
        canUpdate: this.canUpdate,
      },
    });
  },
};
</script>
