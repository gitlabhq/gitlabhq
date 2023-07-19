import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import resolvers from './graphql/resolvers';
import App from './components/app.vue';

export const initOrganizationsGroupsAndProjects = () => {
  const el = document.getElementById('js-organizations-groups-and-projects');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers),
  });

  return new Vue({
    el,
    name: 'OrganizationsGroupsAndProjects',
    apolloProvider,
    render(createElement) {
      return createElement(App);
    },
  });
};
