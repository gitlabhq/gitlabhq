import Vue from 'vue';
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

  return new Vue({
    el,
    name: 'FeatureFlagsEditUserListRoot',
    pinia,
    provide: { userListsDocsPath },
    render(h) {
      return h(EditUserList, {});
    },
  });
};
