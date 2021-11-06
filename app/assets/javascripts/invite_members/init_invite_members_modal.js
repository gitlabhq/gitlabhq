import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(GlToast);

export default function initInviteMembersModal() {
  // https://gitlab.com/gitlab-org/gitlab/-/issues/344955
  // bug lying in wait here for someone to put group and project invite in same screen
  // once that happens we'll need to mount these differently, perhaps split
  // group/project to each mount one, with many ways to open it.
  const el = document.querySelector('.js-invite-members-modal');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
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
          groupSelectFilter: el.dataset.groupsFilter,
          groupSelectParentId: parseInt(el.dataset.parentId, 10),
          areasOfFocusOptions: JSON.parse(el.dataset.areasOfFocusOptions),
          tasksToBeDoneOptions: JSON.parse(el.dataset.tasksToBeDoneOptions || '[]'),
          projects: JSON.parse(el.dataset.projects || '[]'),
          noSelectionAreasOfFocus: JSON.parse(el.dataset.noSelectionAreasOfFocus),
          usersFilter: el.dataset.usersFilter,
          filterId: parseInt(el.dataset.filterId, 10),
        },
      }),
  });
}
