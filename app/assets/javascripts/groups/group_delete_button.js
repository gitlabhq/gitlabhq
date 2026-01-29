import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import DeleteButton from './components/delete_button.vue';

export const initGroupDeleteButton = () => {
  const el = document.querySelector('#js-group-delete-button');

  if (!el) return;

  const {
    formPath,
    confirmPhrase,
    fullName,
    subgroupsCount,
    projectsCount,
    markedForDeletion,
    permanentDeletionDate,
  } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'GroupDeleteButtonRoot',
    render(createElement) {
      return createElement(DeleteButton, {
        props: {
          formPath,
          confirmPhrase,
          fullName,
          subgroupsCount: parseInt(subgroupsCount, 10),
          projectsCount: parseInt(projectsCount, 10),
          markedForDeletion: parseBoolean(markedForDeletion),
          permanentDeletionDate,
        },
      });
    },
  });
};
