import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(GlToast);

let initedInviteMembersModal;

export default function initInviteMembersModal() {
  if (initedInviteMembersModal) {
    // if we already loaded this in another part of the dom, we don't want to do it again
    // else we will stack the modals
    return false;
  }

  // https://gitlab.com/gitlab-org/gitlab/-/issues/344955
  // bug lying in wait here for someone to put group and project invite in same screen
  // once that happens we'll need to mount these differently, perhaps split
  // group/project to each mount one, with many ways to open it.
  const el = document.querySelector('.js-invite-members-modal');

  if (!el) {
    return false;
  }

  initedInviteMembersModal = true;

  return new Vue({
    el,
    name: 'InviteMembersModalRoot',
    provide: {
      newProjectPath: el.dataset.newProjectPath,
    },
    render: (createElement) =>
      createElement(InviteMembersModal, {
        props: {
          ...el.dataset,
          isProject: parseBoolean(el.dataset.isProject),
          accessLevels: JSON.parse(el.dataset.accessLevels),
          defaultAccessLevel: parseInt(el.dataset.defaultAccessLevel, 10),
          tasksToBeDoneOptions: JSON.parse(el.dataset.tasksToBeDoneOptions || '[]'),
          projects: JSON.parse(el.dataset.projects || '[]'),
          usersFilter: el.dataset.usersFilter,
          filterId: parseInt(el.dataset.filterId, 10),
        },
      }),
  });
}
