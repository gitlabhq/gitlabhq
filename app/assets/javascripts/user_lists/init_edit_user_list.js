import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import EditUserList from './components/edit_user_list.vue';
import { useEditUserList } from './store/edit';

export const initEditUserList = () => {
  const el = document.getElementById('js-edit-user-list');

  if (!el) {
    return null;
  }

  const { userListsDocsPath, projectId, userListIid } = el.dataset;

  useEditUserList(pinia).$patch({ projectId, userListIid });

  return initVueApp({
    el,
    name: 'FeatureFlagsEditUserListRoot',
    pinia,
    provide: { userListsDocsPath },
    component: EditUserList,
  });
};
