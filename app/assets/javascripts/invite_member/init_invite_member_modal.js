import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { isInIssuePage, isInDesignPage } from '~/lib/utils/common_utils';
import InviteMemberModal from './components/invite_member_modal.vue';

Vue.use(GlToast);

export default function initInviteMembersModal() {
  const el = document.querySelector('.js-invite-member-modal');

  if (!el || isInDesignPage() || isInIssuePage()) {
    return false;
  }

  const { membersPath } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(InviteMemberModal, {
        props: { membersPath },
      }),
  });
}
