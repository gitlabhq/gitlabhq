import $ from 'jquery';
import Tracking from '~/tracking';

export default function initTrackInviteMembers(userDropdown) {
  const { trackAction, trackLabel } = userDropdown.querySelector(
    '.js-invite-members-track',
  ).dataset;

  $(userDropdown).on('shown.bs.dropdown', () => {
    Tracking.event(undefined, trackAction, {
      label: trackLabel,
    });
  });
}
