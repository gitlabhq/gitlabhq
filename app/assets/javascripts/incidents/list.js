import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import IncidentsList from './components/incidents_list.vue';

Vue.use(VueApollo);
export default () => {
  const selector = '#js-incidents';

  const domEl = document.querySelector(selector);
  const { projectPath, newIssuePath, incidentTemplateName, issuePath } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: selector,
    provide: {
      projectPath,
      incidentTemplateName,
      newIssuePath,
      issuePath,
    },
    apolloProvider,
    components: {
      IncidentsList,
    },
    render(createElement) {
      return createElement('incidents-list');
    },
  });
};
