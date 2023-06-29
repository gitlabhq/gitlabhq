import { GlButton, GlModal, GlFormInput, GlFormTextarea, GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import {
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  TOKEN_NAME_LIMIT,
  MAX_LIST_COUNT,
  CREATE_TOKEN_MODAL,
} from '~/clusters/agents/constants';
import createNewAgentToken from '~/clusters/agents/graphql/mutations/create_new_agent_token.mutation.graphql';
import getClusterAgentQuery from '~/clusters/agents/graphql/queries/get_cluster_agent.query.graphql';
import AgentToken from '~/clusters_list/components/agent_token.vue';
import CreateTokenModal from '~/clusters/agents/components/create_token_modal.vue';
import {
  clusterAgentToken,
  getTokenResponse,
  createAgentTokenErrorResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('CreateTokenModal', () => {
  let wrapper;
  let apolloProvider;
  let trackingSpy;
  let createResponse;

  const clusterAgentId = 'cluster-agent-id';
  const cursor = {
    first: MAX_LIST_COUNT,
    last: null,
  };
  const agentName = 'cluster-agent';
  const projectPath = 'path/to/project';
  const hideModalMock = jest.fn();

  const provide = {
    agentName,
    projectPath,
  };
  const propsData = {
    clusterAgentId,
    cursor,
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAgentInstructions = () => findModal().findComponent(AgentToken);
  const findButtonByVariant = (variant) =>
    findModal()
      .findAllComponents(GlButton)
      .wrappers.find((button) => button.props('variant') === variant);
  const findActionButton = () => findButtonByVariant('confirm');
  const findCancelButton = () => wrapper.findByTestId('agent-token-close-button');

  const expectDisabledAttribute = (element, disabled) => {
    if (disabled) {
      expect(element.attributes('disabled')).toBeDefined();
    } else {
      expect(element.attributes('disabled')).toBeUndefined();
    }
  };

  const createMockApolloProvider = ({ mutationResponse }) => {
    createResponse = jest.fn().mockResolvedValue(mutationResponse);

    return createMockApollo([[createNewAgentToken, createResponse]]);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getClusterAgentQuery,
      data: getTokenResponse.data,
      variables: {
        agentName,
        projectPath,
        ...cursor,
      },
    });
  };

  const createWrapper = () => {
    wrapper = shallowMountExtended(CreateTokenModal, {
      apolloProvider,
      provide,
      propsData,
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: { hide: hideModalMock },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const mockCreatedResponse = (mutationResponse) => {
    apolloProvider = createMockApolloProvider({ mutationResponse });
    writeQuery();

    createWrapper();

    findInput().vm.$emit('input', 'new-token');
    findTextarea().vm.$emit('input', 'new-token-description');
    findActionButton().vm.$emit('click');

    return waitForPromises();
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    apolloProvider = null;
    createResponse = null;
  });

  describe('initial state', () => {
    it('renders an input for the token name', () => {
      expect(findInput().exists()).toBe(true);
      expectDisabledAttribute(findInput(), false);
      expect(findInput().attributes('max-length')).toBe(TOKEN_NAME_LIMIT.toString());
    });

    it('renders a textarea for the token description', () => {
      expect(findTextarea().exists()).toBe(true);
      expectDisabledAttribute(findTextarea(), false);
    });

    it('renders a cancel button', () => {
      expect(findCancelButton().isVisible()).toBe(true);
      expectDisabledAttribute(findCancelButton(), false);
    });

    it('cancel button should hide the modal', () => {
      findCancelButton().vm.$emit('click');
      expect(hideModalMock).toHaveBeenCalled();
    });

    it('renders a disabled next button', () => {
      expect(findActionButton().text()).toBe('Create token');
      expectDisabledAttribute(findActionButton(), true);
    });

    it('sends tracking event for modal shown', () => {
      findModal().vm.$emit('show');
      expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_OPEN, {
        label: EVENT_LABEL_MODAL,
      });
    });
  });

  describe('when user inputs the token name', () => {
    beforeEach(() => {
      expectDisabledAttribute(findActionButton(), true);
      findInput().vm.$emit('input', 'new-token');
    });

    it('enables the next button', () => {
      expectDisabledAttribute(findActionButton(), false);
    });
  });

  describe('when user clicks the create-token button', () => {
    beforeEach(async () => {
      const loadingResponse = new Promise(() => {});
      await mockCreatedResponse(loadingResponse);

      findInput().vm.$emit('input', 'new-token');
      findActionButton().vm.$emit('click');
    });

    it('disables the create-token button', () => {
      expectDisabledAttribute(findActionButton(), true);
    });

    it('hides the cancel button', () => {
      expect(findCancelButton().exists()).toBe(false);
    });
  });

  describe('creating a new token', () => {
    beforeEach(async () => {
      await mockCreatedResponse(clusterAgentToken);
    });

    it('creates a token', () => {
      expect(createResponse).toHaveBeenCalledWith({
        input: { clusterAgentId, name: 'new-token', description: 'new-token-description' },
      });
    });

    it('shows agent instructions', () => {
      expect(findAgentInstructions().props()).toMatchObject({
        agentName,
        agentToken: 'token-secret',
        modalId: CREATE_TOKEN_MODAL,
      });
    });

    it('renders a close button', () => {
      expect(findActionButton().isVisible()).toBe(true);
      expect(findActionButton().text()).toBe('Close');
      expectDisabledAttribute(findActionButton(), false);
    });
  });

  describe('error creating a new token', () => {
    beforeEach(async () => {
      await mockCreatedResponse(createAgentTokenErrorResponse);
    });

    it('displays the error message', () => {
      expect(findAlert().text()).toBe(
        createAgentTokenErrorResponse.data.clusterAgentTokenCreate.errors[0],
      );
    });
  });
});
