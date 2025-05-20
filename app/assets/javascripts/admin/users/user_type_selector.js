import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserTypeSelector from '~/admin/users/components/user_type/user_type_selector.vue';

export const initUserTypeSelector = () => {
  const el = document.getElementById('js-user-type');
  if (!el) return null;

  const { userType, isCurrentUser } = el.dataset;

  return new Vue({
    el,
    name: 'UserTypeSelectorRoot',
    render(createElement) {
      return createElement(UserTypeSelector, {
        props: {
          userType,
          isCurrentUser: parseBoolean(isCurrentUser),
        },
      });
    },
  });
};
