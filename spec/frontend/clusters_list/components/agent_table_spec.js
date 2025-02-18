import { nextTick } from 'vue';
import {
  GlLink,
  GlIcon,
  GlBadge,
  GlTable,
  GlPagination,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import DeleteAgentButton from '~/clusters_list/components/delete_agent_button.vue';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import { I18N_AGENT_TABLE, CONNECT_MODAL_ID } from '~/clusters_list/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { clusterAgents, connectedTimeNow, connectedTimeInactive } from './mock_data';

const defaultConfigHelpUrl =
  '/help/user/clusters/agent/install/_index#create-an-agent-configuration-file';

const defaultProps = {
  agents: clusterAgents,
  maxAgents: null,
};

const DeleteAgentButtonStub = stubComponent(DeleteAgentButton, { template: '<div></div>' });

describe('AgentTable', () => {
  let wrapper;

  const findAgentLink = (at) => wrapper.findAllByTestId('cluster-agent-name-link').at(at);
  const findStatusText = (at) => wrapper.findAllByTestId('cluster-agent-connection-status').at(at);
  const findStatusIcon = (at) => findStatusText(at).findComponent(GlIcon);
  const findLastContactText = (at) => wrapper.findAllByTestId('cluster-agent-last-contact').at(at);
  const findVersionText = (at) => wrapper.findAllByTestId('cluster-agent-version').at(at);
  const findAgentId = (at) => wrapper.findAllByTestId('cluster-agent-id').at(at);
  const findConfiguration = (at) =>
    wrapper.findAllByTestId('cluster-agent-configuration-link').at(at);
  const findDeleteAgentButtons = () => wrapper.findAllComponents(DeleteAgentButton);
  const findTableRow = (at) => wrapper.findComponent(GlTable).find('tbody').findAll('tr').at(at);
  const findSharedBadgeByRow = (at) => findTableRow(at).findComponent(GlBadge);
  const findDeleteAgentButtonByRow = (at) => findTableRow(at).findComponent(DeleteAgentButton);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItem = () =>
    wrapper.findAllComponents(GlDisclosureDropdownItem).at(0);
  const findConnectModal = () => wrapper.findComponent(ConnectToAgentModal);

  const createWrapper = ({ propsData = defaultProps } = {}) => {
    wrapper = mountExtended(AgentTable, {
      propsData,
      stubs: { DeleteAgentButton: DeleteAgentButtonStub },
      directives: { GlModalDirective: createMockDirective('gl-modal-directive') },
    });
  };

  describe('agent table', () => {
    describe('default', () => {
      beforeEach(() => {
        createWrapper();
      });

      it.each`
        agentName    | link          | lineNumber
        ${'agent-1'} | ${'/agent-1'} | ${0}
        ${'agent-2'} | ${'/agent-2'} | ${1}
      `('displays agent link for $agentName', ({ agentName, link, lineNumber }) => {
        expect(findAgentLink(lineNumber).text()).toBe(agentName);
        expect(findAgentLink(lineNumber).attributes('href')).toBe(link);
        expect(findSharedBadgeByRow(lineNumber).exists()).toBe(false);
      });

      it('displays "shared" badge if the agent is shared', () => {
        expect(findSharedBadgeByRow(9).text()).toBe(I18N_AGENT_TABLE.sharedBadgeText);
      });

      it.each`
        agentGraphQLId                      | agentId | lineNumber
        ${'gid://gitlab/Clusters::Agent/1'} | ${'1'}  | ${0}
        ${'gid://gitlab/Clusters::Agent/2'} | ${'2'}  | ${1}
      `(
        'displays agent id as "$agentId" for "$agentGraphQLId" at line $lineNumber',
        ({ agentId, lineNumber }) => {
          expect(findAgentId(lineNumber).text()).toBe(agentId);
        },
      );

      it.each`
        status               | iconName            | lineNumber
        ${'Never connected'} | ${'status-neutral'} | ${0}
        ${'Connected'}       | ${'status-success'} | ${1}
        ${'Not connected'}   | ${'status-alert'}   | ${2}
      `(
        'displays agent connection status as "$status" at line $lineNumber',
        ({ status, iconName, lineNumber }) => {
          expect(findStatusText(lineNumber).text()).toBe(status);
          expect(findStatusIcon(lineNumber).props('name')).toBe(iconName);
        },
      );

      it.each`
        lastContact                                                  | lineNumber
        ${'Never'}                                                   | ${0}
        ${timeagoMixin.methods.timeFormatted(connectedTimeNow)}      | ${1}
        ${timeagoMixin.methods.timeFormatted(connectedTimeInactive)} | ${2}
      `(
        'displays agent last contact time as "$lastContact" at line $lineNumber',
        ({ lastContact, lineNumber }) => {
          expect(findLastContactText(lineNumber).text()).toBe(lastContact);
        },
      );

      it.each`
        agentConfig                 | link                    | lineNumber
        ${'.gitlab/agents/agent-1'} | ${'/agent/full/path'}   | ${0}
        ${'Default configuration'}  | ${defaultConfigHelpUrl} | ${1}
      `(
        'displays config file path as "$agentPath" at line $lineNumber',
        ({ agentConfig, link, lineNumber }) => {
          const findLink = findConfiguration(lineNumber).findComponent(GlLink);

          expect(findLink.attributes('href')).toBe(link);
          expect(findConfiguration(lineNumber).text()).toBe(agentConfig);
        },
      );

      describe('actions menu', () => {
        it('renders dropdown for the actions', () => {
          expect(findDisclosureDropdown().props('toggleText')).toBe('Actions');
        });

        it('renders dropdown item for connecting to cluster action', () => {
          expect(findDisclosureDropdownItem().text()).toBe('Connect to agent-1');
        });

        it('binds dropdown item to the proper modal', () => {
          const binding = getBinding(findDisclosureDropdownItem().element, 'gl-modal-directive');

          expect(binding.value).toBe(CONNECT_MODAL_ID);
        });

        it('renders connect to agent modal when the agent is selected', async () => {
          expect(findConnectModal().exists()).toBe(false);
          findDisclosureDropdownItem().vm.$emit('action');
          findDisclosureDropdownItem().vm.$emit('click');

          await nextTick();

          expect(findConnectModal().props()).toEqual({
            agentId: 'gid://gitlab/Clusters::Agent/1',
            projectPath: 'path/to/project',
            isConfigured: true,
          });
        });

        it('displays delete agent button for each agent except the shared agents', () => {
          expect(findDeleteAgentButtons()).toHaveLength(clusterAgents.length - 1);
          expect(findDeleteAgentButtonByRow(9).exists()).toBe(false);
        });
      });
    });

    describe.each`
      agentMockIdx | agentVersion | agentWarnings               | versionMismatch | text                                    | title
      ${0}         | ${''}        | ${''}                       | ${false}        | ${''}                                   | ${''}
      ${1}         | ${'14.8.0'}  | ${''}                       | ${false}        | ${''}                                   | ${''}
      ${2}         | ${'14.6.0'}  | ${'This agent is outdated'} | ${false}        | ${''}                                   | ${I18N_AGENT_TABLE.versionWarningsTitle}
      ${3}         | ${'14.7.0'}  | ${''}                       | ${true}         | ${I18N_AGENT_TABLE.versionMismatchText} | ${I18N_AGENT_TABLE.versionMismatchTitle}
      ${4}         | ${'14.3.0'}  | ${'This agent is outdated'} | ${true}         | ${I18N_AGENT_TABLE.versionMismatchText} | ${I18N_AGENT_TABLE.versionWarningsMismatchTitle}
    `(
      'when agent version is "$agentVersion" and agent warning is "$agentWarnings"',
      ({ agentMockIdx, agentVersion, agentWarnings, versionMismatch, text, title }) => {
        const currentAgent = clusterAgents[agentMockIdx];
        const showWarning = versionMismatch || agentWarnings?.length;
        const popover = () => wrapper.findByTestId(`popover-${currentAgent.name}`);

        beforeEach(() => {
          createWrapper({
            provide: { projectPath: 'path/to/project' },
            propsData: { agents: [currentAgent] },
          });
        });

        it('shows the correct agent version text', () => {
          expect(findVersionText(0).text()).toBe(agentVersion);
        });

        if (showWarning) {
          it('shows the correct title for the popover', () => {
            expect(popover().props('title')).toBe(title);
          });

          it('renders correct text for the popover', () => {
            expect(popover().text()).toContain(text);
            expect(popover().text()).toContain(agentWarnings);
          });
        } else {
          it("doesn't show a warning icon with a popover", () => {
            expect(findVersionText(0).findComponent(GlIcon).exists()).toBe(false);
            expect(popover().exists()).toBe(false);
          });
        }
      },
    );

    describe('pagination', () => {
      it('should not render pagination buttons when there are no additional pages', () => {
        createWrapper();

        expect(findPagination().exists()).toBe(false);
      });

      it('should render pagination buttons when there are additional pages', () => {
        createWrapper({
          propsData: { agents: [...clusterAgents, ...clusterAgents, ...clusterAgents] },
        });

        expect(findPagination().exists()).toBe(true);
      });

      it('should not render pagination buttons when maxAgents is passed from the parent component', () => {
        createWrapper({
          propsData: {
            agents: [...clusterAgents, ...clusterAgents, ...clusterAgents],
            maxAgents: 6,
          },
        });

        expect(findPagination().exists()).toBe(false);
      });
    });
  });
});
