import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import UserLists from './components/user_lists.vue';
import { useUserLists } from './store/index';

export const initUserLists = () => {
  const el = document.querySelector('#js-user-lists');

  if (!el) {
    return null;
  }

  const { featureFlagsHelpPagePath, errorStateSvgPath, projectId, newUserListPath } = el.dataset;

  useUserLists(pinia).$patch({ projectId });

  return initVueApp({
    el,
    name: 'UserListsRoot',
    pinia,
    provide: {
      featureFlagsHelpPagePath,
      errorStateSvgPath,
      newUserListPath,
    },
    component: UserLists,
  });
};
