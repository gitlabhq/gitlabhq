import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import UserList from '~/user_lists/components/user_list.vue';
import { useUserListShow } from '~/user_lists/store/show';

export default function featureFlagsUserListInit() {
  const el = document.getElementById('js-edit-user-list');

  if (!el) {
    return null;
  }

  const store = useUserListShow();
  store.setInitialData(el.dataset);

  return new Vue({
    el,
    name: 'UserListRoot',
    pinia,
    render(h) {
      const { emptyStatePath } = el.dataset;
      return h(UserList, { props: { emptyStatePath } });
    },
  });
}
