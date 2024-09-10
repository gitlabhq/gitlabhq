import { GlAlert, GlLoadingIcon, GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import Agents from '~/clusters_list/components/agents.vue';
import { AGENT_FEEDBACK_KEY, AGENT_FEEDBACK_ISSUE } from '~/clusters_list/constants';
import getAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_agents.query.graphql';
import getTreeListQuery from '~/clusters_list/graphql/queries/get_tree_list.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  clusterAgentsResponse,
  treeListResponseData,
  expectedAgentsList,
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

  const createWrapper = async ({ props = {}, glFeatures = {}, queryResponse = null } = {}) => {
    const agentQueryResponse = queryResponse || jest.fn().mockResolvedValue(clusterAgentsResponse);
    const treeListQueryResponse = jest.fn().mockResolvedValue(treeListResponseData);

    const apolloProvider = createMockApollo(
      [
        [getAgentsQuery, agentQueryResponse],
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
    });

    await nextTick();
  };

  const findAgentTable = () => wrapper.findComponent(AgentTable);
  const findEmptyState = () => wrapper.findComponent(AgentEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBanner = () => wrapper.findComponent(GlBanner);

  afterEach(() => {
    localStorage.removeItem(AGENT_FEEDBACK_KEY);
  });

  describe('when there is a list of agents', () => {
    beforeEach(() => {
      return createWrapper();
    });

    it('should render agent table', () => {
      expect(findAgentTable().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should pass agent and folder info to table component', () => {
      expect(findAgentTable().props('agents')).toMatchObject(expectedAgentsList);
    });

    it('should emit agents count to the parent component', () => {
      expect(wrapper.emitted().onAgentsLoad).toEqual([[expectedAgentsList.length]]);
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
  });

  describe('when the agent list is empty', () => {
    beforeEach(() => {
      const emptyResponse = {
        data: {
          project: {
            id: 'gid://gitlab/Project/1',
            clusterAgents: {
              nodes: [],
            },
            ciAccessAuthorizedAgents: {
              nodes: [],
            },
            userAccessAuthorizedAgents: {
              nodes: [],
            },
          },
        },
      };
      return createWrapper({ queryResponse: jest.fn().mockResolvedValue(emptyResponse) });
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
      createWrapper({
        queryResponse: jest.fn().mockRejectedValue({}),
      });
      return waitForPromises();
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
