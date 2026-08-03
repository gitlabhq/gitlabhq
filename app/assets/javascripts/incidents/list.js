import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el: selector,
    name: 'IncidentsListRoot',
    component: IncidentsList,
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
  });
};
