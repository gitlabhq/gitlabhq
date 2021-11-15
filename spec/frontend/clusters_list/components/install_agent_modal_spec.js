import { GlAlert, GlButton, GlFormInputGroup } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import { I18N_INSTALL_AGENT_MODAL, MAX_LIST_COUNT } from '~/clusters_list/constants';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import createAgentMutation from '~/clusters_list/graphql/mutations/create_agent.mutation.graphql';
import createAgentTokenMutation from '~/clusters_list/graphql/mutations/create_agent_token.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import {
  createAgentResponse,
  createAgentErrorResponse,
  createAgentTokenResponse,
  createAgentTokenErrorResponse,
  getAgentResponse,
} from '../mocks/apollo';
import ModalStub from '../stubs';

const localVue = createLocalVue();
localVue.use(VueApollo);

const projectPath = 'path/to/project';
const defaultBranchName = 'default';
const maxAgents = MAX_LIST_COUNT;

describe('InstallAgentModal', () => {
  let wrapper;
  let apolloProvider;

  const i18n = I18N_INSTALL_AGENT_MODAL;
  const findModal = () => wrapper.findComponent(ModalStub);
  const findAgentDropdown = () => findModal().findComponent(AvailableAgentsDropdown);
  const findAlert = () => findModal().findComponent(GlAlert);
  const findButtonByVariant = (variant) =>
    findModal()
      .findAll(GlButton)
      .wrappers.find((button) => button.props('variant') === variant);
  const findActionButton = () => findButtonByVariant('confirm');
  const findCancelButton = () => findButtonByVariant('default');

  const expectDisabledAttribute = (element, disabled) => {
    if (disabled) {
      expect(element.attributes('disabled')).toBe('true');
    } else {
      expect(element.attributes('disabled')).toBeUndefined();
    }
  };

  const createWrapper = () => {
    const provide = {
      projectPath,
      kasAddress: 'kas.example.com',
    };

    const propsData = {
      defaultBranchName,
      maxAgents,
    };

    wrapper = shallowMount(InstallAgentModal, {
      attachTo: document.body,
      stubs: {
        GlModal: ModalStub,
      },
      localVue,
      apolloProvider,
      provide,
      propsData,
    });
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

  const mockSelectedAgentResponse = () => {
    createWrapper();
    writeQuery();

    wrapper.vm.setAgentName('agent-name');
    findActionButton().vm.$emit('click');

    return waitForPromises();
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    apolloProvider = null;
  });

  describe('initial state', () => {
    it('renders the dropdown for available agents', () => {
      expect(findAgentDropdown().isVisible()).toBe(true);
      expect(findModal().text()).not.toContain(i18n.basicInstallTitle);
      expect(findModal().findComponent(GlFormInputGroup).exists()).toBe(false);
      expect(findModal().findComponent(GlAlert).exists()).toBe(false);
      expect(findModal().findComponent(CodeBlock).exists()).toBe(false);
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
  });

  describe('an agent is selected', () => {
    beforeEach(() => {
      findAgentDropdown().vm.$emit('agentSelected');
    });

    it('enables the next button', () => {
      expect(findActionButton().isVisible()).toBe(true);
      expectDisabledAttribute(findActionButton(), false);
    });
  });

  describe('registering an agent', () => {
    const createAgentHandler = jest.fn().mockResolvedValue(createAgentResponse);
    const createAgentTokenHandler = jest.fn().mockResolvedValue(createAgentTokenResponse);

    beforeEach(() => {
      apolloProvider = createMockApollo([
        [createAgentMutation, createAgentHandler],
        [createAgentTokenMutation, createAgentTokenHandler],
      ]);

      return mockSelectedAgentResponse(apolloProvider);
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
      const modalText = findModal().text();
      expect(modalText).toContain(i18n.basicInstallTitle);
      expect(modalText).toContain(i18n.basicInstallBody);

      const token = findModal().findComponent(GlFormInputGroup);
      expect(token.props('value')).toBe('mock-agent-token');

      const alert = findModal().findComponent(GlAlert);
      expect(alert.props('title')).toBe(i18n.tokenSingleUseWarningTitle);

      const code = findModal().findComponent(CodeBlock).props('code');
      expect(code).toContain('--agent-token=mock-agent-token');
      expect(code).toContain('--kas-address=kas.example.com');
    });

    describe('error creating agent', () => {
      beforeEach(() => {
        apolloProvider = createMockApollo([
          [createAgentMutation, jest.fn().mockResolvedValue(createAgentErrorResponse)],
        ]);

        return mockSelectedAgentResponse();
      });

      it('displays the error message', () => {
        expect(findAlert().text()).toBe(createAgentErrorResponse.data.createClusterAgent.errors[0]);
      });
    });

    describe('error creating token', () => {
      beforeEach(() => {
        apolloProvider = createMockApollo([
          [createAgentMutation, jest.fn().mockResolvedValue(createAgentResponse)],
          [createAgentTokenMutation, jest.fn().mockResolvedValue(createAgentTokenErrorResponse)],
        ]);

        return mockSelectedAgentResponse();
      });

      it('displays the error message', () => {
        expect(findAlert().text()).toBe(
          createAgentTokenErrorResponse.data.clusterAgentTokenCreate.errors[0],
        );
      });
    });
  });
});
