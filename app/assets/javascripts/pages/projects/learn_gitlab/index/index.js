import Vue from 'vue';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LearnGitlab from '../components/learn_gitlab.vue';

function initLearnGitlab() {
  const el = document.getElementById('js-learn-gitlab-app');

  if (!el) {
    return false;
  }

  const actions = convertObjectPropsToCamelCase(JSON.parse(el.dataset.actions));
  const sections = convertObjectPropsToCamelCase(JSON.parse(el.dataset.sections));
  const project = convertObjectPropsToCamelCase(JSON.parse(el.dataset.project));

  return new Vue({
    el,
    render(createElement) {
      return createElement(LearnGitlab, {
        props: { actions, sections, project },
      });
    },
  });
}

initInviteMembersModal();
initInviteMembersTrigger();

initLearnGitlab();
