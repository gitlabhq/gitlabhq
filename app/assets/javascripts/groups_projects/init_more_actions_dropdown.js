import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MoreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';

export default function InitMoreActionsDropdown() {
  const el = document.querySelector('.js-groups-projects-more-actions-dropdown');

  if (!el) {
    return false;
  }

  const {
    isGroup,
    id,
    leavePath,
    leaveConfirmMessage,
    withdrawPath,
    withdrawConfirmMessage,
    requestAccessPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'MoreActionsDropdownRoot',
    provide: {
      isGroup: parseBoolean(isGroup),
      id,
      leavePath,
      leaveConfirmMessage,
      withdrawPath,
      withdrawConfirmMessage,
      requestAccessPath,
    },
    render: (createElement) => createElement(MoreActionsDropdown),
  });
}
