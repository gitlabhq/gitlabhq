import { GlAlert, GlButton, GlFormInputGroup, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import {
  I18N_AGENT_MODAL,
  MAX_LIST_COUNT,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_SELECT,
  MODAL_TYPE_EMPTY,
  MODAL_TYPE_REGISTER,
} from '~/clusters_list/constants';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import getAgentConfigurations from '~/clusters_list/graphql/queries/agent_configurations.query.graphql';
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
  kasDisabledErrorResponse,
} from '../mocks/apollo';
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

  const configurations = [{ agentName: 'agent-name' }];
  const apolloQueryResponse = {
    data: {
      project: {
        id: '1',
        clusterAgents: { nodes: [] },
        agentConfigurations: { nodes: configurations },
      },
    },
  };

  const findModal = () => wrapper.findComponent(ModalStub);
  const findAgentDropdown = () => findModal().findComponent(AvailableAgentsDropdown);
  const findAlert = () => findModal().findComponent(GlAlert);
  const findButtonByVariant = (variant) =>
    findModal()
      .findAll(GlButton)
      .wrappers.find((button) => button.props('variant') === variant);
  const findActionButton = () => findButtonByVariant('confirm');
  const findCancelButton = () => findButtonByVariant('default');
  const findPrimaryButton = () => wrapper.findByTestId('agent-primary-button');
  const findImage = () => wrapper.findByRole('img', { alt: I18N_AGENT_MODAL.empty_state.altText });

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
      kasAddress,
      emptyStateImage,
    };

    const propsData = {
      defaultBranchName,
      maxAgents,
    };

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

  const mockSelectedAgentResponse = async () => {
    createWrapper();
    writeQuery();

    await waitForPromises();

    wrapper.vm.setAgentName('agent-name');
    findActionButton().vm.$emit('click');

    return waitForPromises();
  };

  beforeEach(async () => {
    apolloProvider = createMockApollo([
      [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse)],
    ]);
    createWrapper();
    await waitForPromises();
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    apolloProvider = null;
  });

  describe('when agent configurations are present', () => {
    const i18n = I18N_AGENT_MODAL.agent_registration;

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

      it('sends the event with the modalType', () => {
        findModal().vm.$emit('show');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
          label: EVENT_LABEL_MODAL,
          property: MODAL_TYPE_REGISTER,
        });
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
        apolloProvider = createMockApollo([
          [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse)],
          [createAgentMutation, createAgentHandler],
          [createAgentTokenMutation, createAgentTokenHandler],
        ]);

        return mockSelectedAgentResponse();
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
            [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse)],
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentErrorResponse)],
          ]);

          return mockSelectedAgentResponse();
        });

        it('displays the error message', () => {
          expect(findAlert().text()).toBe(
            createAgentErrorResponse.data.createClusterAgent.errors[0],
          );
        });
      });

      describe('error creating token', () => {
        beforeEach(() => {
          apolloProvider = createMockApollo([
            [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryResponse)],
            [createAgentMutation, jest.fn().mockResolvedValue(createAgentResponse)],
            [createAgentTokenMutation, jest.fn().mockResolvedValue(createAgentTokenErrorResponse)],
          ]);

          return mockSelectedAgentResponse();
        });

        it('displays the error message', async () => {
          expect(findAlert().text()).toBe(
            createAgentTokenErrorResponse.data.clusterAgentTokenCreate.errors[0],
          );
        });
      });
    });
  });

  describe('when there are no agent configurations present', () => {
    const i18n = I18N_AGENT_MODAL.empty_state;
    const apolloQueryEmptyResponse = {
      data: {
        project: {
          clusterAgents: { nodes: [] },
          agentConfigurations: { nodes: [] },
        },
      },
    };

    beforeEach(() => {
      apolloProvider = createMockApollo([
        [getAgentConfigurations, jest.fn().mockResolvedValue(apolloQueryEmptyResponse)],
      ]);
      createWrapper();
    });

    it('renders empty state image', () => {
      expect(findImage().attributes('src')).toBe(emptyStateImage);
    });

    it('renders a primary button', () => {
      expect(findPrimaryButton().isVisible()).toBe(true);
      expect(findPrimaryButton().text()).toBe(i18n.primaryButton);
    });

    it('sends the event with the modalType', () => {
      findModal().vm.$emit('show');
      expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
        label: EVENT_LABEL_MODAL,
        property: MODAL_TYPE_EMPTY,
      });
    });
  });

  describe('when KAS is disabled', () => {
    const i18n = I18N_AGENT_MODAL.empty_state;
    beforeEach(async () => {
      apolloProvider = createMockApollo([
        [getAgentConfigurations, jest.fn().mockResolvedValue(kasDisabledErrorResponse)],
      ]);

      createWrapper();
      await waitForPromises();
    });

    it('renders empty state image', () => {
      expect(findImage().attributes('src')).toBe(emptyStateImage);
    });

    it('renders an instruction to enable the KAS', () => {
      expect(findModal().text()).toContain(
        sprintf(i18n.enableKasText, { linkStart: '', linkEnd: '' }),
      );
    });

    it('renders a cancel button', () => {
      expect(findCancelButton().isVisible()).toBe(true);
      expect(findCancelButton().text()).toBe(i18n.done);
    });

    it("doesn't render a secondary button", () => {
      expect(findPrimaryButton().exists()).toBe(false);
    });
  });
});
