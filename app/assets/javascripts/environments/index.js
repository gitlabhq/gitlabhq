import Vue from 'vue';
import VueApollo from 'vue-apollo';
import canaryCalloutMixin from './mixins/canary_callout_mixin';
import environmentsComponent from './components/environments_app.vue';
import { parseBoolean } from '../lib/utils/common_utils';
import Translate from '../vue_shared/translate';
import createDefaultClient from '~/lib/graphql';

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
    mixins: [canaryCalloutMixin],
    apolloProvider,
    provide: {
      projectPath: el.dataset.projectPath,
    },
    data() {
      const environmentsData = el.dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        newEnvironmentPath: environmentsData.newEnvironmentPath,
        helpPagePath: environmentsData.helpPagePath,
        deployBoardsHelpPath: environmentsData.deployBoardsHelpPath,
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
          deployBoardsHelpPath: this.deployBoardsHelpPath,
          canCreateEnvironment: this.canCreateEnvironment,
          canReadEnvironment: this.canReadEnvironment,
          ...this.canaryCalloutProps,
        },
      });
    },
  });
};
