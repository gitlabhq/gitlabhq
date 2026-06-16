import Vue from 'vue';
import NewUserList from './components/new_user_list.vue';

export const initNewUserList = () => {
  const el = document.getElementById('js-new-user-list');

  if (!el) {
    return null;
  }

  const { userListsDocsPath, featureFlagsPath, projectId } = el.dataset;

  return new Vue({
    el,
    name: 'FeatureFlagsNewUserListRoot',
    provide: {
      userListsDocsPath,
      featureFlagsPath,
      projectId,
    },
    render(h) {
      return h(NewUserList);
    },
  });
};
