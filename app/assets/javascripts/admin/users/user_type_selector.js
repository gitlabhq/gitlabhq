import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserTypeSelector from './components/user_type/user_type_selector.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initUserTypeSelector = () => {
  const el = document.getElementById('js-user-type');
  if (!el) return null;

  const { userType, isCurrentUser, licenseAllowsAuditorUser } = el.dataset;

  return new Vue({
    el,
    name: 'UserTypeSelectorRoot',
    apolloProvider,
    render(createElement) {
      return createElement(UserTypeSelector, {
        props: {
          userType,
          isCurrentUser: parseBoolean(isCurrentUser),
          licenseAllowsAuditorUser: parseBoolean(licenseAllowsAuditorUser),
        },
      });
    },
  });
};
