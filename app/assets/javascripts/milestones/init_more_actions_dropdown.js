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
      milestoneUrl,
      editUrl,
      closeUrl,
      reopenUrl,
      promoteUrl,
      groupName,
      issueCount,
      mergeRequestCount,
      size,
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
        milestoneUrl,
        editUrl,
        closeUrl,
        reopenUrl,
        promoteUrl,
        groupName,
        issueCount: Number(issueCount),
        mergeRequestCount: Number(mergeRequestCount),
        size: size || 'medium',
      },
      render: (createElement) => createElement(MoreActionsDropdown),
    });
  });
}
