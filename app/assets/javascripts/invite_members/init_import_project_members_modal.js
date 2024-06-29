import Vue from 'vue';
import ImportProjectMembersModal from '~/invite_members/components/import_project_members_modal.vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default function initImportProjectMembersModal() {
  const el = document.querySelector('.js-import-project-members-modal');

  if (!el) {
    return false;
  }

  const { projectId, projectName, reloadPageOnSubmit, usersLimitDataset, addSeatsHref } =
    el.dataset;

  return new Vue({
    el,
    provide: {
      name: projectName,
      addSeatsHref,
    },
    render: (createElement) =>
      createElement(ImportProjectMembersModal, {
        props: {
          projectId,
          projectName,
          reloadPageOnSubmit: parseBoolean(reloadPageOnSubmit),
          usersLimitDataset: convertObjectPropsToCamelCase(JSON.parse(usersLimitDataset || '{}')),
        },
      }),
  });
}
