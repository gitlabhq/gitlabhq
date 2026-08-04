import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupSettingsCreateOrganization from './components/app.vue';

export const initGroupSettingsCreateOrganizations = () => {
  const el = document.getElementById('js-group-settings-create-organization');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'GroupSettingsCreateOrganizationRoot',
    apolloProvider,
    render(createElement) {
      return createElement(GroupSettingsCreateOrganization);
    },
  });
};
