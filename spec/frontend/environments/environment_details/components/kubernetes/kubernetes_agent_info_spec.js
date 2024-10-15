import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import { AGENT_STATUSES, ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';
import waitForPromises from 'helpers/wait_for_promises';

const defaultClusterAgent = {
  name: 'my-agent',
  id: 'gid://gitlab/ClusterAgent/1',
  webPath: 'path/to/agent-page',
};

const connectedTimeNow = new Date();
const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

describe('~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue', () => {
  let wrapper;

  const findAgentLink = () => wrapper.findComponent(GlLink);
  const findAgentStatus = () => wrapper.findByTestId('agent-status');
  const findAgentStatusIcon = () => findAgentStatus().findComponent(GlIcon);
  const findAgentLastUsedDate = () => wrapper.findByTestId('agent-last-used-date');

  const createWrapper = ({ tokens = [] } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(KubernetesAgentInfo, {
        propsData: { clusterAgent: { ...defaultClusterAgent, tokens: { nodes: tokens } } },
        stubs: { TimeAgoTooltip, GlSprintf },
      }),
    );
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the agent name with the link', () => {
      expect(findAgentLink().attributes('href')).toBe(defaultClusterAgent.webPath);
      expect(findAgentLink().text()).toContain('1');
    });
  });

  describe.each`
    lastUsedAt               | status        | lastUsedText
    ${null}                  | ${'unused'}   | ${''}
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
});
