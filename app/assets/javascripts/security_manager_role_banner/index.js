import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import SecurityManagerRoleBanner from './components/security_manager_role_banner.vue';

Vue.use(VueApollo);

export const initSecurityManagerRoleBanner = () => {
  const el = document.getElementById('js-security-manager-role-banner');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'SecurityManagerRoleBannerRoot',
    apolloProvider,
    render(createElement) {
      return createElement(SecurityManagerRoleBanner);
    },
  });
};
