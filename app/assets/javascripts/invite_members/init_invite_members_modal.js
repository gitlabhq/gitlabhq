import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';

Vue.use(GlToast);

export default function initInviteMembersModal() {
  const el = document.querySelector('.js-invite-members-modal');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render: (createElement) =>
      createElement(InviteMembersModal, {
        props: {
          ...el.dataset,
          isProject: parseBoolean(el.dataset.isProject),
          accessLevels: JSON.parse(el.dataset.accessLevels),
        },
      }),
  });
}
