import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MoreActionsDropdown from '~/milestones/components/more_actions_dropdown.vue';

export default function InitMoreActionsDropdown() {
  const containers = document.querySelectorAll('.js-vue-milestone-actions');

  if (!containers.length) {
    return false;
  }

  return containers.forEach((el) => {
    const {
      id,
      title,
      isActive,
      showDelete,
      isDetailPage,
      canReadMilestone,
      milestoneUrl,
      editUrl,
      closeUrl,
      reopenUrl,
      promoteUrl,
      groupName,
      issueCount,
      mergeRequestCount,
    } = el.dataset;

    return new Vue({
      el,
      name: 'MoreActionsDropdownRoot',
      provide: {
        id: Number(id),
        title,
        isActive: parseBoolean(isActive),
        showDelete: parseBoolean(showDelete),
        isDetailPage: parseBoolean(isDetailPage),
        canReadMilestone: parseBoolean(canReadMilestone),
        milestoneUrl,
        editUrl,
        closeUrl,
        reopenUrl,
        promoteUrl,
        groupName,
        issueCount: Number(issueCount),
        mergeRequestCount: Number(mergeRequestCount),
      },
      render: (createElement) => createElement(MoreActionsDropdown),
    });
  });
}
