import { GlButton, GlModal, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ENTER_KEY } from '~/lib/utils/keys';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import deleteAgentMutation from '~/clusters_list/graphql/mutations/delete_agent.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteAgentButton from '~/clusters_list/components/delete_agent_button.vue';
import { DELETE_AGENT_BUTTON } from '~/clusters_list/constants';
import { stubComponent } from 'helpers/stub_component';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mockDeleteResponse, mockErrorDeleteResponse } from '../mocks/apollo';
import { clusterAgentsResponse } from './mock_data';

Vue.use(VueApollo);

const projectPath = 'path/to/project';
const defaultBranchName = 'default';
const agent = {
  id: 'agent-id',
  name: 'agent-name',
  webPath: 'agent-webPath',
};

describe('DeleteAgentButton', () => {
  let wrapper;
  let toast;
  let apolloProvider;
  let deleteResponse;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteBtn = () => wrapper.findComponent(GlButton);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findPrimaryAction = () => findModal().props('actionPrimary');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[attr];
  const findDeleteAgentButtonTooltip = () => wrapper.findByTestId('delete-agent-button-tooltip');
  const getTooltipText = (el) => {
    const binding = getBinding(el, 'gl-tooltip');

    return binding.value;
  };

  const createMockApolloProvider = ({ mutationResponse }) => {
    deleteResponse = jest.fn().mockResolvedValue(mutationResponse);

    return createMockApollo([[deleteAgentMutation, deleteResponse]]);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getAgentsQuery,
      variables: {
        projectPath,
        defaultBranchName,
      },
      data: clusterAgentsResponse.data,
    });
  };

  const createWrapper = async ({
    mutationResponse = mockDeleteResponse,
    provideData = {},
  } = {}) => {
    apolloProvider = createMockApolloProvider({ mutationResponse });
    const defaultProvide = {
      projectPath,
      canAdminCluster: true,
    };
    const propsData = {
      defaultBranchName,
      agent,
    };

    toast = jest.fn();

    wrapper = shallowMountExtended(DeleteAgentButton, {
      apolloProvider,
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData,
      mocks: { $toast: { show: toast } },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: jest.fn(),
          },
        }),
      },
    });

    writeQuery();
    await nextTick();
  };

  const submitAgentToDelete = async () => {
    findDeleteBtn().vm.$emit('click');
    findInput().vm.$emit('input', agent.name);
    await findModal().vm.$emit('primary');
    await waitForPromises();
  };

  beforeEach(() => {
    return createWrapper({});
  });

  afterEach(() => {
    apolloProvider = null;
    deleteResponse = null;
    toast = null;
  });

  describe('delete agent action', () => {
    it('displays a delete button', () => {
      expect(findDeleteBtn().text()).toBe(DELETE_AGENT_BUTTON.deleteButton);
    });

    it("doesn't show a tooltip for the enabled button", () => {
      expect(getTooltipText(findDeleteAgentButtonTooltip().element)).toBe('');
    });

    describe('when clicking the delete button', () => {
      beforeEach(() => {
        findDeleteBtn().vm.$emit('click');
      });

      it('displays a delete confirmation modal', () => {
        expect(findModal().isVisible()).toBe(true);
      });
    });

    describe('when user cannot delete clusters', () => {
      beforeEach(() => {
        createWrapper({ provideData: { canAdminCluster: false } });
      });

      it('disables the button', () => {
        expect(findDeleteBtn().attributes('disabled')).toBeDefined();
      });

      it('shows a disabled tooltip', () => {
        expect(getTooltipText(findDeleteAgentButtonTooltip().element)).toBe(
          DELETE_AGENT_BUTTON.disabledHint,
        );
      });
    });

    describe.each`
      condition                                   | agentName       | isDisabled | mutationCalled
      ${'the input with agent name is missing'}   | ${''}           | ${true}    | ${false}
      ${'the input with agent name is incorrect'} | ${'wrong-name'} | ${true}    | ${false}
      ${'the input with agent name is correct'}   | ${agent.name}   | ${false}   | ${true}
    `('when $condition', ({ agentName, isDisabled, mutationCalled }) => {
      beforeEach(() => {
        findDeleteBtn().vm.$emit('click');
        findInput().vm.$emit('input', agentName);
      });

      it(`${isDisabled ? 'disables' : 'enables'} the modal primary button`, () => {
        expect(findPrimaryActionAttributes('disabled')).toBe(isDisabled);
      });

      describe('when user clicks the modal primary button', () => {
        beforeEach(async () => {
          await findModal().vm.$emit('primary');
        });

        if (mutationCalled) {
          it('calls the delete mutation', () => {
            expect(deleteResponse).toHaveBeenCalledWith({ input: { id: agent.id } });
          });
        } else {
          it("doesn't call the delete mutation", () => {
            expect(deleteResponse).not.toHaveBeenCalled();
          });
        }
      });

      describe('when user presses the enter button', () => {
        beforeEach(async () => {
          await findInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
        });

        if (mutationCalled) {
          it('calls the delete mutation', () => {
            expect(deleteResponse).toHaveBeenCalledWith({ input: { id: agent.id } });
          });
        } else {
          it("doesn't call the delete mutation", () => {
            expect(deleteResponse).not.toHaveBeenCalled();
          });
        }
      });
    });

    describe('when agent was deleted successfully', () => {
      beforeEach(async () => {
        await submitAgentToDelete();
      });

      it('calls the toast action', () => {
        expect(toast).toHaveBeenCalledWith(`${agent.name} successfully deleted`);
      });
    });
  });

  describe('when getting an error deleting agent', () => {
    beforeEach(async () => {
      await createWrapper({ mutationResponse: mockErrorDeleteResponse });
      await submitAgentToDelete();
    });

    it('displays the error message', () => {
      expect(toast).toHaveBeenCalledWith('could not delete agent');
    });
  });

  describe('when the delete modal was closed', () => {
    beforeEach(async () => {
      const loadingResponse = new Promise(() => {});
      await createWrapper({ mutationResponse: loadingResponse });

      await submitAgentToDelete();
    });

    it('reenables the button', async () => {
      expect(findPrimaryActionAttributes('loading')).toBe(true);
      expect(findDeleteBtn().attributes('disabled')).toBeDefined();

      await findModal().vm.$emit('hide');

      expect(findPrimaryActionAttributes('loading')).toBe(false);
      expect(findDeleteBtn().attributes('disabled')).toBeUndefined();
    });

    it('clears the agent name input', async () => {
      expect(findInput().attributes('value')).toBe(agent.name);

      await findModal().vm.$emit('hide');

      expect(findInput().attributes('value')).toBeUndefined();
    });
  });
});
