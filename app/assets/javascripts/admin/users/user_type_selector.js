import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserTypeSelector from '~/admin/users/components/user_type/user_type_selector.vue';

export const initUserTypeSelector = () => {
  const el = document.getElementById('js-user-type');
  if (!el) return null;

  const { userType, isCurrentUser } = el.dataset;

  return initVueApp({
    el,
    name: 'UserTypeSelectorRoot',
    component: UserTypeSelector,
    props: {
      userType,
      isCurrentUser: parseBoolean(isCurrentUser),
    },
  });
};
