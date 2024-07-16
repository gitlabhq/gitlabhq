import Vue from 'vue';
import InviteMembersBanner from '~/groups/components/invite_members_banner.vue';

export default function initInviteMembersBanner() {
  const el = document.querySelector('.js-group-invite-members-banner');

  if (!el) {
    return false;
  }

  const { svgPath, inviteMembersPath, trackLabel, calloutsPath, calloutsFeatureId, groupId } =
    el.dataset;

  return new Vue({
    el,
    provide: {
      svgPath,
      inviteMembersPath,
      trackLabel,
      calloutsPath,
      calloutsFeatureId,
      groupId,
    },
    render: (createElement) => createElement(InviteMembersBanner),
  });
}
