import { GlAlert, GlKeysetPagination, GlLoadingIcon, GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import Agents from '~/clusters_list/components/agents.vue';
import {
  ACTIVE_CONNECTION_TIME,
  AGENT_FEEDBACK_KEY,
  AGENT_FEEDBACK_ISSUE,
} from '~/clusters_list/constants';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

Vue.use(VueApollo);

describe('Agents', () => {
  let wrapper;

  const defaultProps = {
    defaultBranchName: 'default',
  };
  const provideData = {
    projectPath: 'path/to/project',
  };

  const createWrapper = async ({
    props = {},
    glFeatures = {},
    agents = [],
    pageInfo = null,
    trees = [],
    count = 0,
    queryResponse = null,
  }) => {
    const provide = provideData;
    const queryResponseData = {
      data: {
        project: {
          id: '1',
          clusterAgents: {
            nodes: agents,
            pageInfo,
            connections: { nodes: [] },
            tokens: { nodes: [] },
            count,
          },
          repository: { tree: { trees: { nodes: trees, pageInfo } } },
        },
      },
    };
    const agentQueryResponse =
      queryResponse || jest.fn().mockResolvedValue(queryResponseData, provide);

    const apolloProvider = createMockApollo([[getAgentsQuery, agentQueryResponse]]);

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
    });

    await nextTick();
  };

  const findAgentTable = () => wrapper.findComponent(AgentTable);
  const findEmptyState = () => wrapper.findComponent(AgentEmptyState);
  const findPaginationButtons = () => wrapper.findComponent(GlKeysetPagination);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBanner = () => wrapper.findComponent(GlBanner);

  afterEach(() => {
    localStorage.removeItem(AGENT_FEEDBACK_KEY);
  });

  describe('when there is a list of agents', () => {
    let testDate = new Date();
    const agents = [
      {
        __typename: 'ClusterAgent',
        id: '1',
        name: 'agent-1',
        webPath: '/agent-1',
        connections: null,
        tokens: null,
      },
      {
        __typename: 'ClusterAgent',
        id: '2',
        name: 'agent-2',
        webPath: '/agent-2',
        connections: null,
        tokens: {
          nodes: [
            {
              id: 'token-1',
              lastUsedAt: testDate,
            },
          ],
        },
      },
    ];

    const count = 2;

    const trees = [
      {
        id: 'tree-1',
        name: 'agent-2',
        path: '.gitlab/agents/agent-2',
        webPath: '/project/path/.gitlab/agents/agent-2',
      },
    ];

    const expectedAgentsList = [
      {
        id: '1',
        name: 'agent-1',
        webPath: '/agent-1',
        configFolder: undefined,
        status: 'unused',
        lastContact: null,
        connections: null,
        tokens: null,
      },
      {
        id: '2',
        name: 'agent-2',
        configFolder: {
          name: 'agent-2',
          path: '.gitlab/agents/agent-2',
          webPath: '/project/path/.gitlab/agents/agent-2',
        },
        webPath: '/agent-2',
        status: 'active',
        lastContact: new Date(testDate).getTime(),
        connections: null,
        tokens: {
          nodes: [
            {
              lastUsedAt: testDate,
            },
          ],
        },
      },
    ];

    beforeEach(() => {
      return createWrapper({ agents, count, trees });
    });

    it('should render agent table', () => {
      expect(findAgentTable().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should pass agent and folder info to table component', () => {
      expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
    });

    it('should emit agents count to the parent component', () => {
      expect(wrapper.emitted().onAgentsLoad).toEqual([[count]]);
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

          return createWrapper({ glFeatures, agents, count, trees });
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
        return createWrapper({ glFeatures, agents, count, trees });
      });

      it('should render the correct title', () => {
        expect(findBanner().props('title')).toBe('Tell us what you think');
      });

      it('should render the correct issue link', () => {
        expect(findBanner().props('buttonLink')).toBe(AGENT_FEEDBACK_ISSUE);
      });
    });

    describe('when the agent has recently connected tokens', () => {
      it('should set agent status to active', () => {
        expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
      });
    });

    describe('when the agent has tokens connected more then 8 minutes ago', () => {
      const now = new Date();
      testDate = new Date(now.getTime() - ACTIVE_CONNECTION_TIME);
      it('should set agent status to inactive', () => {
        expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
      });
    });

    describe('when the agent has no connected tokens', () => {
      testDate = null;
      it('should set agent status to unused', () => {
        expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
      });
    });

    it('should not render pagination buttons when there are no additional pages', () => {
      expect(findPaginationButtons().exists()).toBe(false);
    });

    describe('when the list has additional pages', () => {
      const pageInfo = {
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'prev',
        endCursor: 'next',
      };

      beforeEach(() => {
        return createWrapper({
          agents,
          pageInfo: {
            ...pageInfo,
            __typename: 'PageInfo',
          },
        });
      });

      it('should render pagination buttons', () => {
        expect(findPaginationButtons().exists()).toBe(true);
      });

      it('should pass pageInfo to the pagination component', () => {
        expect(findPaginationButtons().props()).toMatchObject(pageInfo);
      });

      describe('when limit is passed from the parent component', () => {
        beforeEach(() => {
          return createWrapper({
            props: { limit: 6 },
            agents,
            pageInfo,
          });
        });

        it('should not render pagination buttons', () => {
          expect(findPaginationButtons().exists()).toBe(false);
        });
      });
    });
  });

  describe('when the agent list is empty', () => {
    beforeEach(() => {
      return createWrapper({ agents: [] });
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
    beforeEach(() => {
      return createWrapper({ agents: null });
    });

    it('displays an alert message', () => {
      expect(findAlert().text()).toBe('An error occurred while loading your agents');
    });
  });

  describe('when agents query is loading', () => {
    beforeEach(() => {
      createWrapper({
        queryResponse: jest.fn().mockReturnValue(new Promise(() => {})),
      });
      return waitForPromises();
    });

    it('displays a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
