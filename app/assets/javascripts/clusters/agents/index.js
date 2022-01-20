import Vue from 'vue';
import AgentShowPage from 'ee_else_ce/clusters/agents/components/show.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('#js-cluster-agent-details');

  if (!el) {
    return null;
  }

  const { activityEmptyStateImage, agentName, emptyStateSvgPath, projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      activityEmptyStateImage,
      agentName,
      emptyStateSvgPath,
      projectPath,
    },
    render(createElement) {
      return createElement(AgentShowPage);
    },
  });
};
