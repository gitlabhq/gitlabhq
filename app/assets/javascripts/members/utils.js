import { __ } from '~/locale';

export const generateBadges = (member, isCurrentUser) => [
  {
    show: isCurrentUser,
    text: __("It's you"),
    variant: 'success',
  },
  {
    show: member.user?.blocked,
    text: __('Blocked'),
    variant: 'danger',
  },
  {
    show: member.user?.twoFactorEnabled,
    text: __('2FA'),
    variant: 'info',
  },
];

export const isGroup = member => {
  return Boolean(member.sharedWithGroup);
};

export const isDirectMember = (member, sourceId) => {
  return isGroup(member) || member.source?.id === sourceId;
};

export const isCurrentUser = (member, currentUserId) => {
  return member.user?.id === currentUserId;
};

export const canRemove = (member, sourceId) => {
  return isDirectMember(member, sourceId) && member.canRemove;
};

export const canResend = member => {
  return Boolean(member.invite?.canResend);
};

export const canUpdate = (member, currentUserId, sourceId) => {
  return (
    !isCurrentUser(member, currentUserId) && isDirectMember(member, sourceId) && member.canUpdate
  );
};

// Defined in `ee/app/assets/javascripts/vue_shared/components/members/utils.js`
export const canOverride = () => false;
