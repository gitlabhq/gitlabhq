import { nextTick } from 'vue';
import {
  GlLink,
  GlIcon,
  GlBadge,
  GlTable,
  GlKeysetPagination,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import DeleteAgentButton from '~/clusters_list/components/delete_agent_button.vue';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import { CONNECT_MODAL_ID, MAX_LIST_COUNT } from '~/clusters_list/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { clusterAgents, connectedTimeNow, connectedTimeInactive } from './mock_data';

const defaultConfigHelpUrl =
  '/help/user/clusters/agent/install/_index#create-an-agent-configuration-file';

const versionMismatchText =
  "The agent version do not match each other across your cluster's pods. This can happen when a new agent version was just deployed and Kubernetes is shutting down the old pods.";

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
  const findProject = (at) => wrapper.findAllByTestId('cluster-agent-project-link').at(at);
  const findDeleteAgentButtons = () => wrapper.findAllComponents(DeleteAgentButton);
  const findTableRow = (at) => wrapper.findComponent(GlTable).find('tbody').findAll('tr').at(at);
  const findTableHeaders = () =>
    wrapper.findAll('thead th').wrappers.map((x) => x.text().split('\n')[0].trim());
  const findSharedBadgeByRow = (at) => findTableRow(at).findComponent(GlBadge);
  const findDeleteAgentButtonByRow = (at) => findTableRow(at).findComponent(DeleteAgentButton);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItem = () =>
    wrapper.findAllComponents(GlDisclosureDropdownItem).at(0);
  const findConnectModal = () => wrapper.findComponent(ConnectToAgentModal);

  const sortBy = async (key, desc) => {
    wrapper.findComponent(GlTable).vm.$emit('sort-changed', { sortBy: key, sortDesc: desc });
    await nextTick();
  };

  const findHeader = (label) =>
    wrapper.findAll('thead th').wrappers.find((th) => th.text().split('\n')[0].trim() === label);

  const clickHeader = async (label) => {
    await findHeader(label).trigger('click');
  };

  const ariaSortOf = (label) => findHeader(label).attributes('aria-sort');

  const createWrapper = ({ propsData = defaultProps, isGroup = false } = {}) => {
    wrapper = mountExtended(AgentTable, {
      propsData,
      provide: { isGroup },
      stubs: { DeleteAgentButton: DeleteAgentButtonStub },
      directives: { GlModalDirective: createMockDirective('gl-modal-directive') },
    });
  };

  describe('agent table', () => {
    describe('default', () => {
      beforeEach(async () => {
        createWrapper();
        await sortBy('name', false);
      });

      it('displays correct columns on the project level', () => {
        expect(findTableHeaders()).toEqual([
          'Name',
          'Connection status',
          'Last contact',
          'Version',
          'Agent ID',
          'Configuration',
          '',
        ]);
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
        expect(findSharedBadgeByRow(9).text()).toBe('Shared');
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

    describe('group level', () => {
      beforeEach(() => {
        createWrapper({ isGroup: true });
      });

      it('displays correct columns', () => {
        expect(findTableHeaders()).toEqual([
          'Name',
          'Connection status',
          'Last contact',
          'Version',
          'Agent ID',
          'Project',
          '',
        ]);
      });

      it('displays agent project link', () => {
        expect(findProject(0).text()).toBe('path/to/project');
        expect(findProject(0).attributes('href')).toBe('https://gdk.test/path/to/project');
      });
    });

    describe.each`
      agentMockIdx | agentVersion | agentWarnings               | versionMismatch | text                   | title
      ${0}         | ${''}        | ${''}                       | ${false}        | ${''}                  | ${''}
      ${1}         | ${'14.8.0'}  | ${''}                       | ${false}        | ${''}                  | ${''}
      ${2}         | ${'14.6.0'}  | ${'This agent is outdated'} | ${false}        | ${''}                  | ${'Agent version update required'}
      ${3}         | ${'14.7.0'}  | ${''}                       | ${true}         | ${versionMismatchText} | ${'Agent version mismatch'}
      ${4}         | ${'14.3.0'}  | ${'This agent is outdated'} | ${true}         | ${versionMismatchText} | ${'Agent version mismatch and update'}
    `(
      'when agent version is "$agentVersion" and agent warning is "$agentWarnings"',
      ({ agentMockIdx, agentVersion, agentWarnings, versionMismatch, text, title }) => {
        const currentAgent = clusterAgents[agentMockIdx];
        const showWarning = versionMismatch || agentWarnings?.length;
        const popover = () => wrapper.findComponentByTestId(`popover-${currentAgent.name}`);

        beforeEach(() => {
          createWrapper({ propsData: { agents: [currentAgent] } });
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

    describe('sorting', () => {
      const sortableAgents = [
        {
          id: 'gid://gitlab/Clusters::Agent/2',
          agentId: 2,
          name: 'b-agent',
          status: 'inactive',
          lastContact: 200,
          webPath: '/b',
        },
        {
          id: 'gid://gitlab/Clusters::Agent/10',
          agentId: 10,
          name: 'c-agent',
          status: 'unused',
          lastContact: null,
          webPath: '/c',
        },
        {
          id: 'gid://gitlab/Clusters::Agent/1',
          agentId: 1,
          name: 'a-agent',
          status: 'active',
          lastContact: 100,
          webPath: '/a',
        },
      ];

      const findRowNames = () =>
        wrapper
          .findComponent(GlTable)
          .find('tbody')
          .findAll('tr')
          .wrappers.map((row) => row.find('[data-testid="cluster-agent-name-link"]').text());

      beforeEach(() => {
        createWrapper({ propsData: { agents: sortableAgents } });
      });

      it('orders by most recent contact by default', () => {
        expect(findRowNames()).toEqual(['b-agent', 'a-agent', 'c-agent']);
      });

      it('reverses the name order', async () => {
        await sortBy('name', true);

        expect(findRowNames()).toEqual(['c-agent', 'b-agent', 'a-agent']);
      });

      it('orders by connection status', async () => {
        await sortBy('status', false);

        expect(findRowNames()).toEqual(['a-agent', 'b-agent', 'c-agent']);
      });

      it('keeps agents that never connected last when ordering by last contact', async () => {
        await sortBy('lastContact', false);

        expect(findRowNames()).toEqual(['a-agent', 'b-agent', 'c-agent']);

        await sortBy('lastContact', true);

        expect(findRowNames()).toEqual(['b-agent', 'a-agent', 'c-agent']);
      });

      it('sorts when a column header is clicked', async () => {
        await wrapper.findAll('thead th').at(0).trigger('click');

        expect(findRowNames()).toEqual(['a-agent', 'b-agent', 'c-agent']);
      });

      it('does not offer sorting on columns without a comparator', () => {
        const sortableByKey = Object.fromEntries(
          wrapper
            .findComponent(GlTable)
            .props('fields')
            .map(({ key, sortable }) => [key, sortable]),
        );

        expect(sortableByKey).toMatchObject({
          name: true,
          status: true,
          lastContact: true,
          version: false,
          agentID: true,
          options: false,
        });
      });

      describe('with more agents than fit on one page', () => {
        const manyAgents = Array.from({ length: MAX_LIST_COUNT + 5 }, (_, index) => ({
          id: `gid://gitlab/Clusters::Agent/${index + 1}`,
          agentId: index + 1,
          name: `agent-${index + 1}`,
          status: 'active',
          lastContact: index,
          webPath: `/agent-${index + 1}`,
        }));

        beforeEach(() => {
          createWrapper({ propsData: { agents: manyAgents } });
        });

        it('orders across the whole list, not within the page', async () => {
          await sortBy('name', true);

          expect(findRowNames()[0]).toBe('agent-25');

          findPagination().vm.$emit('next');
          await nextTick();

          expect(findRowNames()).toEqual(['agent-5', 'agent-4', 'agent-3', 'agent-2', 'agent-1']);
        });
      });

      describe('when the parent caps the number of agents', () => {
        beforeEach(() => {
          createWrapper({ propsData: { agents: sortableAgents, maxAgents: 3 } });
        });

        it('does not offer sorting', () => {
          const sortable = wrapper
            .findComponent(GlTable)
            .props('fields')
            .map(({ sortable: isSortable }) => isSortable);

          expect(sortable.every((isSortable) => isSortable === false)).toBe(true);
        });

        it('still orders by most recent contact', () => {
          expect(findRowNames()).toEqual(['b-agent', 'a-agent', 'c-agent']);
        });
      });

      it('orders by agent id numerically, not as a global id string', async () => {
        await sortBy('agentID', false);

        expect(findRowNames()).toEqual(['a-agent', 'b-agent', 'c-agent']);
      });

      describe('at group level', () => {
        const groupAgents = [
          { ...sortableAgents[0], project: { fullPath: 'group/zebra', webUrl: '/zebra' } },
          { ...sortableAgents[1], project: null },
          { ...sortableAgents[2], project: { fullPath: 'group/alpha', webUrl: '/alpha' } },
        ];

        beforeEach(() => {
          createWrapper({ propsData: { agents: groupAgents }, isGroup: true });
        });

        it('orders by project path', async () => {
          await sortBy('project', false);

          expect(findRowNames()).toEqual(['a-agent', 'b-agent', 'c-agent']);
        });

        it('keeps agents without a project last in both directions', async () => {
          await sortBy('project', false);

          expect(findRowNames()[2]).toBe('c-agent');

          await sortBy('project', true);

          expect(findRowNames()[2]).toBe('c-agent');
        });

        it('offers sorting on the project column', () => {
          const project = wrapper
            .findComponent(GlTable)
            .props('fields')
            .find(({ key }) => key === 'project');

          expect(project.sortable).toBe(true);
        });
      });

      it('marks the default column as sorted on first render', () => {
        expect(ariaSortOf('Last contact')).toBe('descending');
        expect(ariaSortOf('Name')).toBe('none');
      });

      it('moves the sort indicator to the clicked column', async () => {
        await clickHeader('Name');

        expect(ariaSortOf('Name')).toBe('ascending');
        expect(ariaSortOf('Last contact')).toBe('none');
      });

      it('toggles the sort indicator when the same column is clicked again', async () => {
        await clickHeader('Name');
        await clickHeader('Name');

        expect(ariaSortOf('Name')).toBe('descending');
        expect(findRowNames()).toEqual(['c-agent', 'b-agent', 'a-agent']);
      });

      it('returns to the first page when the order changes', async () => {
        createWrapper({
          propsData: { agents: [...clusterAgents, ...clusterAgents, ...clusterAgents] },
        });

        findPagination().vm.$emit('next');
        await nextTick();
        expect(findPagination().props('hasPreviousPage')).toBe(true);

        await sortBy('name', true);

        expect(findPagination().props('hasPreviousPage')).toBe(false);
      });
    });

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

      it('should have correct pagination props when on first page', () => {
        createWrapper({
          propsData: { agents: [...clusterAgents, ...clusterAgents, ...clusterAgents] },
        });

        expect(findPagination().props()).toMatchObject({
          hasPreviousPage: false,
          hasNextPage: true,
        });
      });

      it('should navigate to next page when next button is clicked', async () => {
        // Create 50 agents (5 x 10) to ensure we have at least 3 pages (20 per page)
        const manyAgents = [
          ...clusterAgents,
          ...clusterAgents,
          ...clusterAgents,
          ...clusterAgents,
          ...clusterAgents,
        ];
        createWrapper({ propsData: { agents: manyAgents } });

        findPagination().vm.$emit('next');
        await nextTick();

        expect(findPagination().props()).toMatchObject({
          hasPreviousPage: true,
          hasNextPage: true,
        });
      });

      it('should navigate to previous page when prev button is clicked', async () => {
        createWrapper({
          propsData: { agents: [...clusterAgents, ...clusterAgents, ...clusterAgents] },
        });

        // Go to next page first
        findPagination().vm.$emit('next');
        await nextTick();

        // Then go back
        findPagination().vm.$emit('prev');
        await nextTick();

        expect(findPagination().props()).toMatchObject({
          hasPreviousPage: false,
          hasNextPage: true,
        });
      });
    });
  });
});
