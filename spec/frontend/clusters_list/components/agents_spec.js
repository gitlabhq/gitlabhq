import { GlAlert, GlLoadingIcon, GlBanner } from '@gitlab/ui';
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

  const createWrapper = async ({
    props = {},
    glFeatures = {},
    queryResponse = null,
    slots,
  } = {}) => {
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
      slots,
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
    it('should render agent table', async () => {
      createWrapper();
      await waitForPromises();

      expect(findAgentTable().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should pass agent and folder info to table component', async () => {
      createWrapper();
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
    it('displays an alert message', async () => {
      createWrapper({
        queryResponse: jest.fn().mockRejectedValue({}),
      });
      await waitForPromises();

      expect(findAlert().text()).toBe('An error occurred while loading your agents');
    });

    it('emits `kasDisabled` event if the error is related to KAS being disabled', async () => {
      const error = new Error(KAS_DISABLED_ERROR);
      createWrapper({
        queryResponse: jest.fn().mockRejectedValue(error),
      });
      await waitForPromises();

      expect(wrapper.emitted().kasDisabled).toEqual([[true]]);
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
