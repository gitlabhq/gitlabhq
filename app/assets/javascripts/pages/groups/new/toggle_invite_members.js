import { parseBoolean } from '~/lib/utils/common_utils';

export default function initToggleInviteMembers() {
  const inviteMembersSection = document.querySelector('.js-invite-members-section');
  const setupForCompanyRadios = document.querySelectorAll('input[name="group[setup_for_company]"]');

  if (inviteMembersSection && setupForCompanyRadios.length) {
    setupForCompanyRadios.forEach((el) => {
      el.addEventListener('change', (event) => {
        inviteMembersSection.classList.toggle('hidden', !parseBoolean(event.target.value));
      });
    });
  }
}
