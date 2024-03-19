import { GlAlert, GlButton, GlFormInputGroup, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf, s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import AgentToken from '~/clusters_list/components/agent_token.vue';
import {
  I18N_AGENT_MODAL,
  MAX_LIST_COUNT,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_SELECT,
  MODAL_TYPE_EMPTY,
  MODAL_TYPE_REGISTER,
  INSTALL_AGENT_MODAL_ID,
} from '~/clusters_list/constants';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import getAgentConfigurations from '~/clusters_list/graphql/queries/agent_configurations.query.graphql';
import createAgentMutation from '~/clusters_list/graphql/mutations/create_agent.mutation.graphql';
import createAgentTokenMutation from '~/clusters_list/graphql/mutations/create_agent_token.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  createAgentResponse,
  createAgentErrorResponse,
  createAgentTokenResponse,
  createAgentTokenErrorResponse,
  getAgentResponse,
  kasDisabledErrorResponse,
} from '../mocks/apollo';
import ModalStub from '../stubs';

Vue.use(VueApollo);

const projectPath = 'path/to/project';
const kasAddress = 'kas.example.com';
const emptyStateImage = 'path/to/image';
const defaultBranchName = 'default';
const maxAgents = MAX_LIST_COUNT;
const i18n = I18N_AGENT_MODAL;

describe('InstallAgentModal', () => {
  let wrapper;
  let apolloProvider;
  let trackingSpy;

  const configurations = [{ agentName: 'agent-name' }];
  const apolloQueryResponse = (configurationsNodes = configurations) => ({
    data: {
      project: {
        __typename: 'Project',
        id: 'project-1',
        clusterAgents: { nodes: [] },
        agentConfigurations: { nodes: configurationsNodes },
      },
    },
  });

  const provide = {
    projectPath,
    kasAddress,
    emptyStateImage,
  };

  const propsData = {
    defaultBranchName,
    maxAgents,
  };

  const findModal = () => wrapper.findComponent(ModalStub);
  const findAgentDropdown = () => findModal().findComponent(AvailableAgentsDropdown);
  const findAlert = () => findModal().findComponent(GlAlert);
  const findAgentInstructions = () => findModal().findComponent(AgentToken);
  const findButtonByVariant = (variant) =>
    findModal()
      .findAllComponents(GlButton)
      .wrappers.find((button) => button.props('variant') === variant);
  const findActionButton = () => findButtonByVariant('confirm');
  const findCancelButton = () => findButtonByVariant('default');
  const findPrimaryButton = () => wrapper.findByTestId('agent-primary-button');

  const expectDisabledAttribute = (element, disabled) => {
    if (disabled) {
      expect(element.attributes('disabled')).toBeDefined();
    } else {
      expect(element.attributes('disabled')).toBeUndefined();
    }
  };

  const createWrapper = (mockApolloProvider) => {
    apolloProvider =
      mockApolloProvider ||
      createMockApollo([
        [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse())],
      ]);

    wrapper = shallowMountExtended(InstallAgentModal, {
      attachTo: document.body,
      stubs: {
        GlSprintf,
        GlModal: ModalStub,
      },
      apolloProvider,
      provide,
      propsData,
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getAgentsQuery,
      variables: {
        projectPath,
        defaultBranchName,
        first: MAX_LIST_COUNT,
        last: null,
      },
      data: getAgentResponse.data,
    });
  };

  const mockSelectedAgentResponse = (mockApolloProvider) => {
    createWrapper(mockApolloProvider);
    writeQuery();

    wrapper.vm.setAgentName('agent-name');
    findActionButton().vm.$emit('click');

    return waitForPromises();
  };

  afterEach(() => {
    apolloProvider = null;
  });

  describe('when KAS is enabled', () => {
    describe('initial state', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders the dropdown for available agents', () => {
        expect(findAgentDropdown().isVisible()).toBe(true);
      });

      it("doesn't render agent installation instructions", () => {
        expect(findModal().findComponent(GlFormInputGroup).exists()).toBe(false);
        expect(findModal().findComponent(GlAlert).exists()).toBe(false);
      });

      it('renders a cancel button', () => {
        expect(findCancelButton().isVisible()).toBe(true);
        expectDisabledAttribute(findCancelButton(), false);
      });

      it('renders a disabled next button', () => {
        expect(findActionButton().isVisible()).toBe(true);
        expect(findActionButton().text()).toBe(i18n.registerAgentButton);
        expectDisabledAttribute(findActionButton(), true);
      });

      it('sends the event with the modalType', () => {
        findModal().vm.$emit('show');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
          label: EVENT_LABEL_MODAL,
          property: MODAL_TYPE_REGISTER,
        });
      });
    });

    describe('when there are 10 or more available agent configurations', () => {
      it('displays an alert with Terraform instructions', async () => {
        const configurationsNodes = Array(10).fill(configurations);
        const mockApolloProvider = createMockApollo([
          [
            getAgentConfigurations,
            jest.fn().mockResolvedValue(apolloQueryResponse(configurationsNodes)),
          ],
        ]);

        createWrapper(mockApolloProvider);
        await waitForPromises();

        expect(findAlert().text()).toMatchInterpolatedText(
          s__('ClusterAgents|To manage more agents, %{linkStart}use Terraform%{linkEnd}.'),
        );
      });

      it('displays an alert with a warning when there are 100 or more configurations', async () => {
        const configurationsNodes = Array(100).fill(configurations);
        const mockApolloProvider = createMockApollo([
          [
            getAgentConfigurations,
            jest.fn().mockResolvedValue(apolloQueryResponse(configurationsNodes)),
          ],
        ]);

        createWrapper(mockApolloProvider);
        await waitForPromises();

        expect(findAlert().text()).toContain(
          s__('ClusterAgents|We only support 100 agents on the UI.'),
        );
      });
    });

    describe('an agent is selected', () => {
      beforeEach(() => {
        createWrapper();
        findAgentDropdown().vm.$emit('agentSelected');
      });

      it('enables the next button', () => {
        expect(findActionButton().isVisible()).toBe(true);
        expectDisabledAttribute(findActionButton(), false);
      });

      it('sends the correct tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_SELECT, {
          label: EVENT_LABEL_MODAL,
        });
      });
    });

    describe('registering an agent', () => {
      const createAgentHandler = jest.fn().mockResolvedValue(createAgentResponse);
      const createAgentTokenHandler = jest.fn().mockResolvedValue(createAgentTokenResponse);

      beforeEach(() => {
        const mockApolloProvider = createMockApollo([
          [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse())],
          [createAgentMutation, createAgentHandler],
          [createAgentTokenMutation, createAgentTokenHandler],
        ]);

        return mockSelectedAgentResponse(mockApolloProvider);
      });

      it('creates an agent and token', () => {
        expect(createAgentHandler).toHaveBeenCalledWith({
          input: { name: 'agent-name', projectPath },
        });

        expect(createAgentTokenHandler).toHaveBeenCalledWith({
          input: { clusterAgentId: 'agent-id', name: 'agent-name' },
        });
      });

      it('renders a close button', () => {
        expect(findActionButton().isVisible()).toBe(true);
        expect(findActionButton().text()).toBe(i18n.close);
        expectDisabledAttribute(findActionButton(), false);
      });

      it('shows agent instructions', () => {
        expect(findAgentInstructions().props()).toMatchObject({
          agentName: 'agent-name',
          agentToken: 'mock-agent-token',
          modalId: INSTALL_AGENT_MODAL_ID,
        });
      });

      describe('error creating agent', () => {
        beforeEach(() => {
          const mockApolloProvider = createMockApollo([
            [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse())],
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentErrorResponse)],
          ]);

          return mockSelectedAgentResponse(mockApolloProvider);
        });

        it('displays the error message', () => {
          expect(findAlert().text()).toBe(
            createAgentErrorResponse.data.createClusterAgent.errors[0],
          );
        });
      });

      describe('error creating token', () => {
        beforeEach(() => {
          const mockApolloProvider = createMockApollo([
            [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse())],
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentResponse)],
            [createAgentTokenMutation, jest.fn().mockResolvedValue(createAgentTokenErrorResponse)],
          ]);

          return mockSelectedAgentResponse(mockApolloProvider);
        });

        it('displays the error message', () => {
          expect(findAlert().text()).toBe(
            createAgentTokenErrorResponse.data.clusterAgentTokenCreate.errors[0],
          );
        });
      });
    });
  });

  describe('when KAS is disabled', () => {
    beforeEach(async () => {
      const mockApolloProvider = createMockApollo([
        [getAgentConfigurations, jest.fn().mockResolvedValue(kasDisabledErrorResponse)],
      ]);

      createWrapper(mockApolloProvider);
      await waitForPromises();
    });

    it('renders an instruction to enable the KAS', () => {
      expect(findModal().text()).toContain(
        sprintf(i18n.enableKasText, { linkStart: '', linkEnd: '' }),
      );
    });

    it('renders a cancel button', () => {
      expect(findCancelButton().isVisible()).toBe(true);
      expect(findCancelButton().text()).toBe(i18n.close);
    });

    it("doesn't render a secondary button", () => {
      expect(findPrimaryButton().exists()).toBe(false);
    });

    it('sends the event with the modalType', () => {
      findModal().vm.$emit('show');
      expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
        label: EVENT_LABEL_MODAL,
        property: MODAL_TYPE_EMPTY,
      });
    });
  });
});
