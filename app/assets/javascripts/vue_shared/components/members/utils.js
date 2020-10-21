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
