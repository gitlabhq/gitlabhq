import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormInputGroup,
  GlFormGroup,
  GlFormInput,
  GlSprintf,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import AgentToken from '~/clusters_list/components/agent_token.vue';
import {
  MAX_LIST_COUNT,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  MODAL_TYPE_EMPTY,
  MODAL_TYPE_REGISTER,
  INSTALL_AGENT_MODAL_ID,
} from '~/clusters_list/constants';
import getAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_agents.query.graphql';
import createAgentMutation from 'ee_else_ce/clusters_list/graphql/mutations/create_agent.mutation.graphql';
import createAgentTokenMutation from '~/clusters_list/graphql/mutations/create_agent_token.mutation.graphql';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  createAgentResponse,
  createAgentErrorResponse,
  clusterAgentsResponse,
} from 'ee_else_ce_jest/clusters_list/components/mock_data';
import { createAgentTokenResponse, createAgentTokenErrorResponse } from '../mocks/apollo';
import ModalStub from '../stubs';

Vue.use(VueApollo);

const projectPath = 'path/to/project';
const kasAddress = 'kas.example.com';
const emptyStateImage = 'path/to/image';
const defaultBranchName = 'default';
const maxAgents = MAX_LIST_COUNT;

describe('InstallAgentModal', () => {
  let wrapper;
  let apolloProvider;
  let trackingSpy;

  const glabCommand = 'glab cluster agent bootstrap <agent-name>';

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
  const findForm = () => findModal().findComponent(GlForm);
  const findFormGroup = () => findModal().findComponent(GlFormGroup);
  const findAgentInput = () => findModal().findComponent(GlFormInput);
  const findAlert = () => findModal().findComponent(GlAlert);
  const findAgentInstructions = () => findModal().findComponent(AgentToken);
  const findButtonByVariant = (variant) =>
    findModal()
      .findAllComponents(GlButton)
      .wrappers.find((button) => button.props('variant') === variant);
  const findActionButton = () => findButtonByVariant('confirm');
  const findCancelButton = () => findButtonByVariant('default');
  const findPrimaryButton = () => wrapper.findByTestId('agent-primary-button');
  const findModalCopyButton = () => wrapper.findComponent(ModalCopyButton);
  const findCodeBlock = () => wrapper.findComponent(CodeBlockHighlighted);

  const createWrapper = (mockApolloProvider, kasDisabled) => {
    apolloProvider = mockApolloProvider;

    wrapper = shallowMountExtended(InstallAgentModal, {
      attachTo: document.body,
      stubs: {
        GlSprintf,
        GlModal: ModalStub,
      },
      apolloProvider,
      provide,
      propsData: {
        ...propsData,
        kasDisabled,
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getAgentsQuery,
      variables: {
        projectPath,
      },
      data: clusterAgentsResponse.data,
    });
  };

  const mockSelectedAgentResponse = (mockApolloProvider) => {
    createWrapper(mockApolloProvider);
    writeQuery();

    findAgentInput().vm.$emit('input', 'agent-name');
    findActionButton().vm.$emit('click');
  };

  describe('when KAS is enabled', () => {
    describe('initial state', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders a title for bootstrap with Flux block', () => {
        expect(findModal().text()).toContain('Option 1: Bootstrap the agent with Flux');
      });

      it('renders a description for bootstrap with Flux block', () => {
        expect(findModal().text()).toContain(
          'If Flux is installed in the cluster, you can install and register the agent from the command line:',
        );
      });

      it('renders a code block with a bootstrap with Flux CLI command', () => {
        expect(findCodeBlock().props('language')).toBe('shell');
        expect(findCodeBlock().props('code')).toBe(glabCommand);
      });

      it('renders a button to copy a bootstrap with Flux CLI command', () => {
        expect(findModalCopyButton().props()).toMatchObject({
          text: glabCommand,
          modalId: INSTALL_AGENT_MODAL_ID,
        });
      });

      it('renders a command to list available bootstrap with Flux options', () => {
        expect(findModal().text()).toContain(
          sprintf('You can view a list of options with %{codeStart}--help%{codeEnd}.', {
            codeStart: '',
            codeEnd: '',
          }),
        );
      });

      it('renders a link to the bootstrap agent with Flux help page', () => {
        expect(findModal().text()).toContain(
          sprintf("If you're bootstrapping the agent with Flux, you can close this dialog.", {
            linkStart: '',
            linkEnd: '',
          }),
        );
      });

      it('renders a title for bootstrap with the UI block', () => {
        expect(findModal().text()).toContain('Option 2: Create and register an agent with the UI');
      });

      it('renders the input for new agent name', () => {
        expect(findAgentInput().attributes('placeholder')).toBe('Name of new agent');
      });

      it("doesn't render agent installation instructions", () => {
        expect(findModal().findComponent(GlFormInputGroup).exists()).toBe(false);
        expect(findModal().findComponent(GlAlert).exists()).toBe(false);
      });

      it('renders a cancel button', () => {
        expect(findCancelButton().isVisible()).toBe(true);
      });

      it('renders a next button', () => {
        expect(findActionButton().isVisible()).toBe(true);
        expect(findActionButton().text()).toBe('Create and register');
      });

      it('sends the event with the modalType', () => {
        findModal().vm.$emit('show');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
          label: EVENT_LABEL_MODAL,
          property: MODAL_TYPE_REGISTER,
        });
      });
    });

    describe('an agent name is submitted', () => {
      const createAgentHandler = jest.fn().mockResolvedValue(createAgentResponse);
      const createAgentTokenHandler = jest.fn().mockResolvedValue(createAgentTokenResponse);

      beforeEach(() => {
        const mockApolloProvider = createMockApollo([
          [createAgentMutation, createAgentHandler],
          [createAgentTokenMutation, createAgentTokenHandler],
        ]);
        createWrapper(mockApolloProvider);
      });

      it('shows invalid feedback if the agent name is empty', async () => {
        findActionButton().vm.$emit('click');
        await nextTick();

        expect(findAgentInput().attributes('state')).toBeUndefined();
        expect(findFormGroup().attributes('invalid-feedback')).toBe('This field is required.');
      });

      it('renders agent input as valid if the agent name is present', async () => {
        findAgentInput().vm.$emit('input', 'agentSelected');
        findActionButton().vm.$emit('click');
        await nextTick();

        expect(findAgentInput().attributes('state')).toBe('true');
      });

      it('triggers the create agent mutation on next button click', () => {
        findAgentInput().vm.$emit('input', 'agentSelected');
        findActionButton().vm.$emit('click');
        expect(createAgentHandler).toHaveBeenCalled();
      });

      it('triggers the create agent mutation on the form submit', () => {
        findAgentInput().vm.$emit('input', 'agentSelected');
        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        expect(createAgentHandler).toHaveBeenCalled();
      });
    });

    describe('registering an agent', () => {
      const createAgentHandler = jest.fn().mockResolvedValue(createAgentResponse);
      const createAgentTokenHandler = jest.fn().mockResolvedValue(createAgentTokenResponse);

      beforeEach(async () => {
        const mockApolloProvider = createMockApollo([
          [createAgentMutation, createAgentHandler],
          [createAgentTokenMutation, createAgentTokenHandler],
        ]);

        mockSelectedAgentResponse(mockApolloProvider);
        await waitForPromises();
      });

      it('creates an agent and token', () => {
        expect(createAgentHandler).toHaveBeenCalledWith({
          input: { name: 'agent-name', projectPath },
        });

        expect(createAgentTokenHandler).toHaveBeenCalledWith({
          input: { clusterAgentId: 'agent-id', name: 'agent-name' },
        });
      });

      it('emits `clusterAgentCreated` event', () => {
        expect(wrapper.emitted('clusterAgentCreated')).toEqual([['agent-name']]);
      });

      it('renders success alert', () => {
        expect(findAlert().props('variant')).toBe('success');
        expect(findAlert().text()).toBe('agent-name successfully created.');
      });

      it('renders a close button', () => {
        expect(findActionButton().isVisible()).toBe(true);
        expect(findActionButton().text()).toBe('Close');
      });

      it('shows agent instructions', () => {
        expect(findAgentInstructions().props()).toMatchObject({
          agentName: 'agent-name',
          agentToken: 'mock-agent-token',
          modalId: INSTALL_AGENT_MODAL_ID,
        });
      });

      describe('error creating agent', () => {
        beforeEach(async () => {
          const mockApolloProvider = createMockApollo([
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentErrorResponse)],
          ]);

          mockSelectedAgentResponse(mockApolloProvider);
          await waitForPromises();
        });

        it('displays the error message', () => {
          expect(findAlert().text()).toBe(
            createAgentErrorResponse.data.createClusterAgent.errors[0],
          );
        });
      });

      describe('error creating token', () => {
        beforeEach(async () => {
          const mockApolloProvider = createMockApollo([
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentResponse)],
            [createAgentTokenMutation, jest.fn().mockResolvedValue(createAgentTokenErrorResponse)],
          ]);

          mockSelectedAgentResponse(mockApolloProvider);
          await waitForPromises();
        });

        it('displays the error message', () => {
          expect(findAlert().text()).toBe(
            createAgentTokenErrorResponse.data.clusterAgentTokenCreate.errors[0],
          );
        });
      });
    });

    describe('calling showModalForAgent from outside of the component', () => {
      let showModalSpy;

      beforeEach(() => {
        createWrapper();

        showModalSpy = jest.spyOn(wrapper.vm.$refs.modal, 'show');
        wrapper.vm.showModalForAgent('new-agent-name');
      });

      it('should open the modal', () => {
        expect(showModalSpy).toHaveBeenCalled();
      });

      it('should update the input with the provided agent name', () => {
        expect(findAgentInput().attributes('value')).toBe('new-agent-name');
      });

      it('should update the bootstrap command with the new agent name', () => {
        expect(findCodeBlock().props('code')).toBe('glab cluster agent bootstrap new-agent-name');
      });
    });
  });

  describe('when KAS is disabled', () => {
    beforeEach(() => {
      createWrapper(null, true);
    });

    it('renders an instruction to enable the KAS', () => {
      expect(findModal().text()).toContain(
        "Your instance doesn't have the GitLab Agent Server (KAS) set up. Ask a GitLab Administrator to install it.",
      );
    });

    it('renders a cancel button', () => {
      expect(findCancelButton().isVisible()).toBe(true);
      expect(findCancelButton().text()).toBe('Close');
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
