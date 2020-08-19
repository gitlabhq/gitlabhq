import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import IncidentsList from './components/incidents_list.vue';

Vue.use(VueApollo);
export default () => {
  const selector = '#js-incidents';

  const domEl = document.querySelector(selector);
  const {
    projectPath,
    newIssuePath,
    incidentTemplateName,
    incidentType,
    issuePath,
    publishedAvailable,
    emptyListSvgPath,
  } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: selector,
    provide: {
      projectPath,
      incidentTemplateName,
      incidentType,
      newIssuePath,
      issuePath,
      publishedAvailable,
      emptyListSvgPath,
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
