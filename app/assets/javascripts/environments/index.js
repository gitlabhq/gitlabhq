import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '../lib/utils/common_utils';
import Translate from '../vue_shared/translate';
import environmentsComponent from './components/environments_app.vue';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('environments-list-view');
  return new Vue({
    el,
    components: {
      environmentsComponent,
    },
    apolloProvider,
    provide: {
      projectPath: el.dataset.projectPath,
      defaultBranchName: el.dataset.defaultBranchName,
    },
    data() {
      const environmentsData = el.dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        newEnvironmentPath: environmentsData.newEnvironmentPath,
        helpPagePath: environmentsData.helpPagePath,
        canCreateEnvironment: parseBoolean(environmentsData.canCreateEnvironment),
        canReadEnvironment: parseBoolean(environmentsData.canReadEnvironment),
      };
    },
    render(createElement) {
      return createElement('environments-component', {
        props: {
          endpoint: this.endpoint,
          newEnvironmentPath: this.newEnvironmentPath,
          helpPagePath: this.helpPagePath,
          canCreateEnvironment: this.canCreateEnvironment,
          canReadEnvironment: this.canReadEnvironment,
        },
      });
    },
  });
};
