import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import NewUserList from './components/new_user_list.vue';

export const initNewUserList = () => {
  const el = document.getElementById('js-new-user-list');

  if (!el) {
    return null;
  }

  const { userListsDocsPath, featureFlagsPath, projectId } = el.dataset;

  return initVueApp({
    el,
    name: 'FeatureFlagsNewUserListRoot',
    provide: {
      userListsDocsPath,
      featureFlagsPath,
      projectId,
    },
    component: NewUserList,
  });
};
