import { pinia } from '~/pinia/instance';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import UserList from '~/user_lists/components/user_list.vue';
import { useUserListShow } from '~/user_lists/store/show';

export default function featureFlagsUserListInit() {
  const el = document.getElementById('js-edit-user-list');

  if (!el) {
    return null;
  }

  const store = useUserListShow();
  store.setInitialData(el.dataset);

  const { emptyStatePath } = el.dataset;

  return initVueApp({
    el,
    name: 'UserListRoot',
    pinia,
    component: UserList,
    props: { emptyStatePath },
  });
}
