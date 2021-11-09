import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
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
    textQuery,
    authorUsernameQuery,
    assigneeUsernameQuery,
    slaFeatureAvailable,
    canCreateIncident,
  } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: selector,
    components: {
      IncidentsList,
    },
    provide: {
      projectPath,
      incidentTemplateName,
      incidentType,
      newIssuePath,
      issuePath,
      publishedAvailable: parseBoolean(publishedAvailable),
      emptyListSvgPath,
      textQuery,
      authorUsernameQuery,
      assigneeUsernameQuery,
      slaFeatureAvailable: parseBoolean(slaFeatureAvailable),
      canCreateIncident: parseBoolean(canCreateIncident),
    },
    apolloProvider,
    render(createElement) {
      return createElement('incidents-list');
    },
  });
};
