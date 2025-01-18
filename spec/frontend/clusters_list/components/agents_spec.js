import { GlAlert, GlLoadingIcon, GlBanner, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import Agents from '~/clusters_list/components/agents.vue';
import {
  AGENT_FEEDBACK_KEY,
  AGENT_FEEDBACK_ISSUE,
  KAS_DISABLED_ERROR,
} from '~/clusters_list/constants';
import getAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_agents.query.graphql';
import getSharedAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_shared_agents.query.graphql';
import getTreeListQuery from '~/clusters_list/graphql/queries/get_tree_list.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  clusterAgentsResponse,
  treeListResponseData,
  expectedAgentsList,
  sharedAgentsResponse,
} from 'ee_else_ce_jest/clusters_list/components/mock_data';

Vue.use(VueApollo);

describe('Agents', () => {
  let wrapper;

  const defaultProps = {
    defaultBranchName: 'default',
  };
  const provideData = {
    projectPath: 'path/to/project',
  };

  const projectId = 'gid://gitlab/Project/1';

  const emptyAgentsResponse = {
    data: {
      project: {
        id: projectId,
        clusterAgents: { nodes: [], count: 0 },
      },
    },
  };

  const emptySharedAgentsResponse = {
    data: {
      project: {
        id: projectId,
        ciAccessAuthorizedAgents: { nodes: [] },
        userAccessAuthorizedAgents: { nodes: [] },
      },
    },
  };

  const emptyTreeListResponse = {
    data: {
      project: {
        id: projectId,
        repository: {
          tree: {
            trees: {
              nodes: [],
            },
          },
        },
      },
    },
  };

  const createWrapper = async ({
    props = {},
    glFeatures = {},
    agentQueryResponse = jest.fn().mockResolvedValue(clusterAgentsResponse),
    treeListQueryResponse = jest.fn().mockResolvedValue(emptyTreeListResponse),
    sharedAgentsQueryResponse = jest.fn().mockResolvedValue(emptySharedAgentsResponse),
    slots,
  } = {}) => {
    const apolloProvider = createMockApollo(
      [
        [getAgentsQuery, agentQueryResponse],
        [getSharedAgentsQuery, sharedAgentsQueryResponse],
        [getTreeListQuery, treeListQueryResponse],
      ],
      {},
      { typePolicies: { Query: { fields: { project: { merge: true } } } } },
    );

    wrapper = shallowMount(Agents, {
      apolloProvider,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...provideData,
        glFeatures,
      },
      stubs: {
        GlBanner,
        LocalStorageSync,
      },
      slots,
    });

    await nextTick();
  };

  const findAgentTabs = () => wrapper.findComponent(GlTabs);
  const findTab = () => wrapper.findAllComponents(GlTab);
  const findAgentTable = () => wrapper.findComponent(AgentTable);
  const findEmptyState = () => wrapper.findComponent(AgentEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBanner = () => wrapper.findComponent(GlBanner);

  afterEach(() => {
    localStorage.removeItem(AGENT_FEEDBACK_KEY);
  });

  describe('when there is a list of agents', () => {
    it('should not render empty state', async () => {
      createWrapper();
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
    });

    it('should render agent tabs', async () => {
      createWrapper();
      await waitForPromises();

      expect(findAgentTabs().exists()).toBe(true);
    });

    it('should render agent table', async () => {
      createWrapper();
      await waitForPromises();

      expect(findAgentTable().exists()).toBe(true);
    });

    it('should pass agent and folder info to table component', async () => {
      createWrapper({ treeListQueryResponse: jest.fn().mockResolvedValue(treeListResponseData) });
      await waitForPromises();

      expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
    });

    it('should emit agents count to the parent component', async () => {
      createWrapper();
      await waitForPromises();

      expect(wrapper.emitted().onAgentsLoad).toEqual([[expectedAgentsList.length]]);
    });

    it('should render a slot for alerts if provided', async () => {
      createWrapper({ slots: { alerts: 'slotContent' } });
      await waitForPromises();

      expect(wrapper.text()).toContain('slotContent');
    });

    describe.each`
      featureFlagEnabled | localStorageItemExists | bannerShown
      ${true}            | ${false}               | ${true}
      ${true}            | ${true}                | ${false}
      ${false}           | ${true}                | ${false}
      ${false}           | ${false}               | ${false}
    `(
      'when the feature flag enabled is $featureFlagEnabled and dismissed localStorage item exists is $localStorageItemExists',
      ({ featureFlagEnabled, localStorageItemExists, bannerShown }) => {
        const glFeatures = {
          showGitlabAgentFeedback: featureFlagEnabled,
        };
        beforeEach(() => {
          if (localStorageItemExists) {
            localStorage.setItem(AGENT_FEEDBACK_KEY, true);
          }

          return createWrapper({ glFeatures });
        });

        it(`should ${bannerShown ? 'show' : 'hide'} the feedback banner`, () => {
          expect(findBanner().exists()).toBe(bannerShown);
        });
      },
    );

    describe('when the agent feedback banner is present', () => {
      const glFeatures = {
        showGitlabAgentFeedback: true,
      };
      beforeEach(() => {
        return createWrapper({ glFeatures });
      });

      it('should render the correct title', () => {
        expect(findBanner().props('title')).toBe('Tell us what you think');
      });

      it('should render the correct issue link', () => {
        expect(findBanner().props('buttonLink')).toBe(AGENT_FEEDBACK_ISSUE);
      });
    });

    describe('agent tabs', () => {
      it('should render project agents tab when the agents query has returned data', async () => {
        createWrapper();
        await waitForPromises();

        expect(findTab().at(0).attributes('title')).toBe('Project agents');
      });

      it('should render project agents tab with alert when the agents query has errored', async () => {
        createWrapper({ agentQueryResponse: jest.fn().mockRejectedValue({}) });
        await waitForPromises();

        expect(findTab().at(0).attributes('title')).toBe('Project agents');
        expect(findTab().at(0).text()).toBe('An error occurred while loading your agents');
      });

      it('should not render shared agents tab when the query has not returned data', async () => {
        createWrapper();
        await waitForPromises();

        expect(findTab()).toHaveLength(1);
      });

      it('should render shared agents tab when the query has returned data', async () => {
        createWrapper({
          sharedAgentsQueryResponse: jest.fn().mockResolvedValue(sharedAgentsResponse),
        });
        await waitForPromises();

        expect(findTab()).toHaveLength(2);
        expect(findTab().at(1).attributes('title')).toBe('Shared agents');
      });

      it('should render shared agents tab with alert when the agents query has errored', async () => {
        createWrapper({ sharedAgentsQueryResponse: jest.fn().mockRejectedValue({}) });
        await waitForPromises();

        expect(findTab().at(1).attributes('title')).toBe('Shared agents');
        expect(findTab().at(1).text()).toBe('An error occurred while loading your agents');
      });

      it('should render configurations tab when the query has returned data', async () => {
        createWrapper({
          treeListQueryResponse: jest.fn().mockResolvedValue(treeListResponseData),
        });
        await waitForPromises();

        expect(findTab()).toHaveLength(2);
        expect(findTab().at(1).attributes('title')).toBe('Available configurations');
      });
    });
  });

  describe('sharedAgentsList computed property', () => {
    const ciAccessAgent = sharedAgentsResponse.data.project.ciAccessAuthorizedAgents.nodes[0];
    const userAccessAgent = sharedAgentsResponse.data.project.userAccessAuthorizedAgents.nodes[0];

    const createSharedAgentsResponse = (ciAgents, userAgents) => ({
      data: {
        project: {
          id: projectId,
          ciAccessAuthorizedAgents: { nodes: ciAgents },
          userAccessAuthorizedAgents: { nodes: userAgents },
        },
      },
    });

    it('filters out agents from the same project', async () => {
      const sameProjectAgent = {
        agent: {
          ...userAccessAgent.agent,
          project: { id: projectId, fullPath: provideData.projectPath },
        },
      };

      const updatedResponse = createSharedAgentsResponse([ciAccessAgent], [sameProjectAgent]);

      createWrapper({
        sharedAgentsQueryResponse: jest.fn().mockResolvedValue(updatedResponse),
      });

      await waitForPromises();

      expect(findTab()).toHaveLength(2);
      expect(findTab().at(1).attributes('title')).toBe('Shared agents');

      expect(findTab().at(1).findComponent(AgentTable).props('agents')).toHaveLength(1);
    });

    it('filters out agents duplicates', async () => {
      const updatedResponse = createSharedAgentsResponse(
        [ciAccessAgent],
        [ciAccessAgent, userAccessAgent],
      );

      createWrapper({
        sharedAgentsQueryResponse: jest.fn().mockResolvedValue(updatedResponse),
      });

      await waitForPromises();

      expect(findTab()).toHaveLength(2);
      expect(findTab().at(1).attributes('title')).toBe('Shared agents');

      expect(findTab().at(1).findComponent(AgentTable).props('agents')).toHaveLength(2);
    });
  });

  describe('agent list update', () => {
    const initialResponse = { ...clusterAgentsResponse };
    const newAgent = {
      ...clusterAgentsResponse.data.project.clusterAgents.nodes[0],
      id: 'gid://gitlab/Clusters::Agent/999',
    };
    const updatedResponse = {
      data: {
        project: {
          ...clusterAgentsResponse.data.project,
          clusterAgents: {
            nodes: [...clusterAgentsResponse.data.project.clusterAgents.nodes, newAgent],
            count: 3,
          },
        },
      },
    };

    beforeEach(() => {
      const agentQueryResponse = jest
        .fn()
        .mockResolvedValueOnce(initialResponse)
        .mockResolvedValueOnce(updatedResponse);

      createWrapper({ agentQueryResponse });
    });

    it('should update the agent table when query data changes', async () => {
      await waitForPromises();

      expect(findAgentTable().props('agents')).toHaveLength(expectedAgentsList.length);

      await wrapper.vm.$apollo.queries.agents.refetch();
      await waitForPromises();

      expect(findAgentTable().props('agents')).toHaveLength(expectedAgentsList.length + 1);
    });

    it('should navigate to the project agents tab', async () => {
      // The project agents tab is opened by default
      await waitForPromises();
      expect(findAgentTabs().props('value')).toBe(0);

      // Open the second tab
      findAgentTabs().vm.$emit('input', 1);
      await waitForPromises();
      expect(findAgentTabs().props('value')).toBe(1);

      // On data change, go back to the project agents tab
      await wrapper.vm.$apollo.queries.agents.refetch();
      await waitForPromises();
      expect(findAgentTabs().props('value')).toBe(0);
    });
  });

  describe('when the agent list and configuration list are empty', () => {
    beforeEach(async () => {
      createWrapper({
        agentQueryResponse: jest.fn().mockResolvedValue(emptyAgentsResponse),
      });
      await waitForPromises();
      await nextTick();
    });

    it('should render empty state', () => {
      expect(findAgentTable().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });

    it('should not show agent feedback alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when agents query has errored', () => {
    it('displays an alert message', async () => {
      createWrapper({
        agentQueryResponse: jest.fn().mockRejectedValue({}),
      });
      await waitForPromises();

      expect(findAlert().text()).toBe('An error occurred while loading your agents');
    });

    it('emits `kasDisabled` event if the error is related to KAS being disabled', async () => {
      const error = new Error(KAS_DISABLED_ERROR);
      createWrapper({
        agentQueryResponse: jest.fn().mockRejectedValue(error),
      });
      await waitForPromises();

      expect(wrapper.emitted().kasDisabled).toEqual([[true]]);
    });
  });

  describe('when agents query is loading', () => {
    beforeEach(() => {
      createWrapper({
        agentQueryResponse: jest.fn().mockReturnValue(new Promise(() => {})),
      });
    });

    it('displays a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
