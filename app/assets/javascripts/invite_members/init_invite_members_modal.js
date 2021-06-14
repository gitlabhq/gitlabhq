import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

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
          defaultAccessLevel: parseInt(el.dataset.defaultAccessLevel, 10),
          groupSelectFilter: el.dataset.groupsFilter,
          groupSelectParentId: parseInt(el.dataset.parentId, 10),
        },
      }),
  });
}
