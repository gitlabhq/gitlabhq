import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { membersProvideData } from 'ee_else_ce/invite_members/utils';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

Vue.use(GlToast);

export default (function initInviteMembersModal() {
  let inviteMembersModal;

  return () => {
    if (!inviteMembersModal) {
      // https://gitlab.com/gitlab-org/gitlab/-/issues/344955
      // bug lying in wait here for someone to put group and project invite in same screen
      // once that happens we'll need to mount these differently, perhaps split
      // group/project to each mount one, with many ways to open it.
      const el = document.querySelector('.js-invite-members-modal');

      if (!el) {
        return false;
      }

      inviteMembersModal = new Vue({
        el,
        name: 'InviteMembersModalRoot',
        provide: membersProvideData(el),
        render: (createElement) =>
          createElement(InviteMembersModal, {
            props: {
              ...el.dataset,
              isProject: parseBoolean(el.dataset.isProject),
              accessLevels: JSON.parse(el.dataset.accessLevels),
              defaultAccessLevel: parseInt(el.dataset.defaultAccessLevel, 10),
              defaultMemberRoleId: parseInt(el.dataset.defaultMemberRoleId, 10) || null,
              usersLimitDataset: convertObjectPropsToCamelCase(
                JSON.parse(el.dataset.usersLimitDataset || '{}'),
              ),
              activeTrialDataset: convertObjectPropsToCamelCase(
                JSON.parse(el.dataset.activeTrialDataset || '{}'),
              ),
              reloadPageOnSubmit: parseBoolean(el.dataset.reloadPageOnSubmit),
            },
          }),
      });
    }
    return inviteMembersModal;
  };
})();
