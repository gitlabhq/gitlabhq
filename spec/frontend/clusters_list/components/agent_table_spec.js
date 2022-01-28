import { GlLink, GlIcon } from '@gitlab/ui';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import DeleteAgentButton from '~/clusters_list/components/delete_agent_button.vue';
import { ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import timeagoMixin from '~/vue_shared/mixins/timeago';

const connectedTimeNow = new Date();
const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

const provideData = {
  projectPath: 'path/to/project',
};
const propsData = {
  agents: [
    {
      name: 'agent-1',
      id: 'agent-1-id',
      configFolder: {
        webPath: '/agent/full/path',
      },
      webPath: '/agent-1',
      status: 'unused',
      lastContact: null,
      tokens: null,
    },
    {
      name: 'agent-2',
      id: 'agent-2-id',
      webPath: '/agent-2',
      status: 'active',
      lastContact: connectedTimeNow.getTime(),
      tokens: {
        nodes: [
          {
            lastUsedAt: connectedTimeNow,
          },
        ],
      },
    },
    {
      name: 'agent-3',
      id: 'agent-3-id',
      webPath: '/agent-3',
      status: 'inactive',
      lastContact: connectedTimeInactive.getTime(),
      tokens: {
        nodes: [
          {
            lastUsedAt: connectedTimeInactive,
          },
        ],
      },
    },
  ],
};

const DeleteAgentButtonStub = stubComponent(DeleteAgentButton, {
  template: `<div></div>`,
});

describe('AgentTable', () => {
  let wrapper;

  const findAgentLink = (at) => wrapper.findAllByTestId('cluster-agent-name-link').at(at);
  const findStatusIcon = (at) => wrapper.findAllComponents(GlIcon).at(at);
  const findStatusText = (at) => wrapper.findAllByTestId('cluster-agent-connection-status').at(at);
  const findLastContactText = (at) => wrapper.findAllByTestId('cluster-agent-last-contact').at(at);
  const findConfiguration = (at) =>
    wrapper.findAllByTestId('cluster-agent-configuration-link').at(at);
  const findDeleteAgentButton = () => wrapper.findAllComponents(DeleteAgentButton);

  beforeEach(() => {
    wrapper = mountExtended(AgentTable, {
      propsData,
      provide: provideData,
      stubs: {
        DeleteAgentButton: DeleteAgentButtonStub,
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('agent table', () => {
    it.each`
      agentName    | link          | lineNumber
      ${'agent-1'} | ${'/agent-1'} | ${0}
      ${'agent-2'} | ${'/agent-2'} | ${1}
    `('displays agent link', ({ agentName, link, lineNumber }) => {
      expect(findAgentLink(lineNumber).text()).toBe(agentName);
      expect(findAgentLink(lineNumber).attributes('href')).toBe(link);
    });

    it.each`
      status               | iconName               | lineNumber
      ${'Never connected'} | ${'status-neutral'}    | ${0}
      ${'Connected'}       | ${'status-success'}    | ${1}
      ${'Not connected'}   | ${'severity-critical'} | ${2}
    `('displays agent connection status', ({ status, iconName, lineNumber }) => {
      expect(findStatusText(lineNumber).text()).toBe(status);
      expect(findStatusIcon(lineNumber).props('name')).toBe(iconName);
    });

    it.each`
      lastContact                                                  | lineNumber
      ${'Never'}                                                   | ${0}
      ${timeagoMixin.methods.timeFormatted(connectedTimeNow)}      | ${1}
      ${timeagoMixin.methods.timeFormatted(connectedTimeInactive)} | ${2}
    `('displays agent last contact time', ({ lastContact, lineNumber }) => {
      expect(findLastContactText(lineNumber).text()).toBe(lastContact);
    });

    it.each`
      agentPath                   | hasLink  | lineNumber
      ${'.gitlab/agents/agent-1'} | ${true}  | ${0}
      ${'.gitlab/agents/agent-2'} | ${false} | ${1}
    `('displays config file path', ({ agentPath, hasLink, lineNumber }) => {
      const findLink = findConfiguration(lineNumber).find(GlLink);

      expect(findLink.exists()).toBe(hasLink);
      expect(findConfiguration(lineNumber).text()).toBe(agentPath);
    });

    it('displays actions menu for each agent', () => {
      expect(findDeleteAgentButton()).toHaveLength(3);
    });
  });
});
