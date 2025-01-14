import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import InviteGroupsModal from '~/invite_members/components/invite_groups_modal.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(GlToast);

let initedInviteGroupsModal;

export default function initInviteGroupsModal() {
  if (initedInviteGroupsModal) {
    // if we already loaded this in another part of the dom, we don't want to do it again
    // else we will stack the modals
    return false;
  }

  // https://gitlab.com/gitlab-org/gitlab/-/issues/344955
  // bug lying in wait here for someone to put group and project invite in same screen
  // once that happens we'll need to mount these differently, perhaps split
  // group/project to each mount one, with many ways to open it.
  const el = document.querySelector('.js-invite-groups-modal');

  if (!el) {
    return false;
  }

  initedInviteGroupsModal = true;

  return new Vue({
    el,
    provide: {
      freeUsersLimit: parseInt(el.dataset.freeUsersLimit, 10),
      overageMembersModalAvailable: parseBoolean(el.dataset.overageMembersModalAvailable),
      hasGitlabSubscription: parseBoolean(el.dataset.hasGitlabSubscription),
      inviteWithCustomRoleEnabled: parseBoolean(el.dataset.inviteWithCustomRoleEnabled),
    },
    render: (createElement) =>
      createElement(InviteGroupsModal, {
        props: {
          ...el.dataset,
          isProject: parseBoolean(el.dataset.isProject),
          accessLevels: JSON.parse(el.dataset.accessLevels),
          defaultAccessLevel: parseInt(el.dataset.defaultAccessLevel, 10),
          groupSelectFilter: el.dataset.groupsFilter,
          groupSelectParentId: parseInt(el.dataset.parentId, 10),
          invalidGroups: JSON.parse(el.dataset.invalidGroups || '[]'),
          freeUserCapEnabled: parseBoolean(el.dataset.freeUserCapEnabled),
          reloadPageOnSubmit: parseBoolean(el.dataset.reloadPageOnSubmit),
        },
      }),
  });
}
