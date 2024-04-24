import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AgentShowPage from 'ee_else_ce/clusters/agents/components/show.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';

export default () => {
  const el = document.querySelector('#js-cluster-agent-details');

  if (!el) {
    return null;
  }

  const {
    activityEmptyStateImage,
    agentName,
    canAdminVulnerability,
    emptyStateSvgPath,
    projectPath,
    kasAddress,
    kasInstallVersion,
    canAdminCluster,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(),
    provide: {
      activityEmptyStateImage,
      agentName,
      canAdminVulnerability,
      emptyStateSvgPath,
      projectPath,
      kasAddress,
      kasInstallVersion,
      canAdminCluster: parseBoolean(canAdminCluster),
    },
    render(createElement) {
      return createElement(AgentShowPage);
    },
  });
};
