import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AgentShowPage from './components/show.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('#js-cluster-agent-details');

  if (!el) {
    return null;
  }

  const defaultClient = createDefaultClient();
  const { agentName, projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({ defaultClient }),
    render(createElement) {
      return createElement(AgentShowPage, {
        props: {
          agentName,
          projectPath,
        },
      });
    },
  });
};
