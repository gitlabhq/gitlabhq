import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlLink, GlSprintf, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import KubernetesAgentInfo from '~/environments/components/kubernetes_agent_info.vue';
import { AGENT_STATUSES, ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getK8sClusterAgentQuery from '~/environments/graphql/queries/k8s_cluster_agent.query.graphql';

Vue.use(VueApollo);

const propsData = {
  agentName: 'my-agent',
  agentId: '1',
  agentProjectPath: 'path/to/agent-config-project',
};

const mockClusterAgent = {
  id: '1',
  name: 'token-1',
  webPath: 'path/to/agent-page',
};

const connectedTimeNow = new Date();
const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

describe('~/environments/components/kubernetes_agent_info.vue', () => {
  let wrapper;
  let agentQueryResponse;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAgentLink = () => wrapper.findComponent(GlLink);
  const findAgentStatus = () => wrapper.findByTestId('agent-status');
  const findAgentStatusIcon = () => findAgentStatus().findComponent(GlIcon);
  const findAgentLastUsedDate = () => wrapper.findByTestId('agent-last-used-date');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = ({ tokens = [], queryResponse = null } = {}) => {
    const clusterAgent = { ...mockClusterAgent, tokens: { nodes: tokens } };

    agentQueryResponse =
      queryResponse ||
      jest.fn().mockResolvedValue({ data: { project: { id: 'project-1', clusterAgent } } });
    const apolloProvider = createMockApollo([[getK8sClusterAgentQuery, agentQueryResponse]]);

    wrapper = extendedWrapper(
      shallowMount(KubernetesAgentInfo, {
        apolloProvider,
        propsData,
        stubs: { TimeAgoTooltip, GlSprintf },
      }),
    );
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows loading icon while fetching the agent details', async () => {
      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('sends expected params', async () => {
      await waitForPromises();

      const variables = {
        agentName: propsData.agentName,
        projectPath: propsData.agentProjectPath,
      };

      expect(agentQueryResponse).toHaveBeenCalledWith(variables);
    });

    it('renders the agent name with the link', async () => {
      await waitForPromises();

      expect(findAgentLink().attributes('href')).toBe(mockClusterAgent.webPath);
      expect(findAgentLink().text()).toContain(mockClusterAgent.id);
    });
  });

  describe.each`
    lastUsedAt               | status        | lastUsedText
    ${null}                  | ${'unused'}   | ${KubernetesAgentInfo.i18n.neverConnectedText}
    ${connectedTimeNow}      | ${'active'}   | ${'just now'}
    ${connectedTimeInactive} | ${'inactive'} | ${'8 minutes ago'}
  `('when agent connection status is "$status"', ({ lastUsedAt, status, lastUsedText }) => {
    beforeEach(async () => {
      const tokens = [{ id: 'token-id', lastUsedAt }];
      createWrapper({ tokens });
      await waitForPromises();
    });

    it('displays correct status text', () => {
      expect(findAgentStatus().text()).toBe(AGENT_STATUSES[status].name);
    });

    it('displays correct status icon', () => {
      expect(findAgentStatusIcon().props('name')).toBe(AGENT_STATUSES[status].icon);
      expect(findAgentStatusIcon().attributes('class')).toBe(AGENT_STATUSES[status].class);
    });

    it('displays correct last used date status', () => {
      expect(findAgentLastUsedDate().text()).toBe(lastUsedText);
    });
  });

  describe('when the agent query has errored', () => {
    beforeEach(() => {
      createWrapper({ clusterAgent: null, queryResponse: jest.fn().mockRejectedValue() });
      return waitForPromises();
    });

    it('displays an alert message', () => {
      expect(findAlert().text()).toBe(KubernetesAgentInfo.i18n.loadingError);
    });
  });
});
