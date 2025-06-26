import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  AGENT_STATUSES,
  ACTIVE_CONNECTION_TIME,
  CONNECT_MODAL_ID,
} from '~/clusters_list/constants';
import waitForPromises from 'helpers/wait_for_promises';

const defaultClusterAgent = {
  name: 'my-agent',
  id: 'gid://gitlab/ClusterAgent/1',
  webPath: 'path/to/agent-page',
  project: {
    fullPath: 'gitlab-org/gitlab',
  },
};

const connectedTimeNow = new Date();
const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

describe('~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue', () => {
  let wrapper;

  const findAgentLink = () => wrapper.findComponent(GlLink);
  const findAgentStatus = () => wrapper.findByTestId('agent-status');
  const findAgentStatusIcon = () => findAgentStatus().findComponent(GlIcon);
  const findAgentLastUsedDate = () => wrapper.findByTestId('agent-last-used-date');
  const findConnectButton = () => wrapper.findComponent(GlButton);
  const findConnectModal = () => wrapper.findComponent(ConnectToAgentModal);

  const createWrapper = ({ tokens = [], clusterAgent = defaultClusterAgent } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(KubernetesAgentInfo, {
        propsData: { clusterAgent: { ...clusterAgent, tokens: { nodes: tokens } } },
        stubs: { TimeAgoTooltip, GlSprintf },
        directives: {
          GlModalDirective: createMockDirective('gl-modal-directive'),
        },
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

    it('renders the connect to agent button', () => {
      expect(findConnectButton().text()).toBe('Connect to agent');
    });

    it('renders the connect to agent modal with correct props', () => {
      expect(findConnectModal().props()).toMatchObject({
        agentId: defaultClusterAgent.id,
        projectPath: 'gitlab-org/gitlab',
        isConfigured: true,
      });
    });

    it('connect button has modal directive', () => {
      const binding = getBinding(findConnectButton().element, 'gl-modal-directive');

      expect(binding.value).toBe(CONNECT_MODAL_ID);
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
