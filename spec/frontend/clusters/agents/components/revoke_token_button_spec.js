import { GlButton, GlModal, GlFormInput, GlTooltip } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ENTER_KEY } from '~/lib/utils/keys';
import RevokeTokenButton from '~/clusters/agents/components/revoke_token_button.vue';
import getClusterAgentQuery from '~/clusters/agents/graphql/queries/get_cluster_agent.query.graphql';
import revokeTokenMutation from '~/clusters/agents/graphql/mutations/revoke_token.mutation.graphql';
import { MAX_LIST_COUNT } from '~/clusters/agents/constants';
import { getTokenResponse, mockRevokeResponse, mockErrorRevokeResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('RevokeTokenButton', () => {
  let wrapper;
  let toast;
  let apolloProvider;
  let revokeSpy;

  const token = {
    id: 'token-id',
    name: 'token-name',
  };
  const cursor = {
    first: MAX_LIST_COUNT,
    last: null,
  };
  const agentName = 'cluster-agent';
  const projectPath = 'path/to/project';

  const defaultProvide = {
    agentName,
    projectPath,
    canAdminCluster: true,
  };
  const propsData = {
    token,
    cursor,
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findRevokeBtn = () => wrapper.findComponent(GlButton);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findPrimaryAction = () => findModal().props('actionPrimary');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[attr];

  const createMockApolloProvider = ({ mutationResponse }) => {
    revokeSpy = jest.fn().mockResolvedValue(mutationResponse);

    return createMockApollo([[revokeTokenMutation, revokeSpy]]);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getClusterAgentQuery,
      variables: {
        agentName,
        projectPath,
        ...cursor,
      },
      data: getTokenResponse.data,
    });
  };

  const createWrapper = async ({
    mutationResponse = mockRevokeResponse,
    provideData = {},
  } = {}) => {
    apolloProvider = createMockApolloProvider({ mutationResponse });

    toast = jest.fn();

    wrapper = shallowMountExtended(RevokeTokenButton, {
      apolloProvider,
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      propsData,
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: jest.fn(),
          },
        }),
        GlTooltip,
      },
      mocks: { $toast: { show: toast } },
    });

    writeQuery();
    await nextTick();
  };

  const submitTokenToRevoke = async () => {
    findRevokeBtn().vm.$emit('click');
    findInput().vm.$emit('input', token.name);
    await findModal().vm.$emit('primary');
    await waitForPromises();
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    apolloProvider = null;
    revokeSpy = null;
  });

  describe('revoke token action', () => {
    it('displays a revoke button', () => {
      expect(findRevokeBtn().attributes('aria-label')).toBe('Revoke token');
    });

    describe('when user cannot revoke token', () => {
      beforeEach(() => {
        createWrapper({ provideData: { canAdminCluster: false } });
      });

      it('disabled the button', () => {
        expect(findRevokeBtn().attributes('disabled')).toBeDefined();
      });

      it('shows a disabled tooltip', () => {
        expect(findTooltip().attributes('title')).toBe(
          'Requires a Maintainer or greater role to perform this action',
        );
      });
    });

    describe('when user can create a token and clicks the button', () => {
      beforeEach(() => {
        findRevokeBtn().vm.$emit('click');
      });

      it('displays a delete confirmation modal', () => {
        expect(findModal().isVisible()).toBe(true);
      });

      describe.each`
        condition                                   | tokenName       | isDisabled | mutationCalled
        ${'the input with token name is missing'}   | ${''}           | ${true}    | ${false}
        ${'the input with token name is incorrect'} | ${'wrong-name'} | ${true}    | ${false}
        ${'the input with token name is correct'}   | ${token.name}   | ${false}   | ${true}
      `('when $condition', ({ tokenName, isDisabled, mutationCalled }) => {
        beforeEach(() => {
          findRevokeBtn().vm.$emit('click');
          findInput().vm.$emit('input', tokenName);
        });

        it(`${isDisabled ? 'disables' : 'enables'} the modal primary button`, () => {
          expect(findPrimaryActionAttributes('disabled')).toBe(isDisabled);
        });

        describe('when user clicks the modal primary button', () => {
          beforeEach(async () => {
            await findModal().vm.$emit('primary');
          });

          if (mutationCalled) {
            it('calls the revoke mutation', () => {
              expect(revokeSpy).toHaveBeenCalledWith({ input: { id: token.id } });
            });
          } else {
            it("doesn't call the revoke mutation", () => {
              expect(revokeSpy).not.toHaveBeenCalled();
            });
          }
        });

        describe('when user presses the enter button', () => {
          beforeEach(async () => {
            await findInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
          });

          if (mutationCalled) {
            it('calls the revoke mutation', () => {
              expect(revokeSpy).toHaveBeenCalledWith({ input: { id: token.id } });
            });
          } else {
            it("doesn't call the revoke mutation", () => {
              expect(revokeSpy).not.toHaveBeenCalled();
            });
          }
        });
      });
    });

    describe('when token was revoked successfully', () => {
      beforeEach(async () => {
        await submitTokenToRevoke();
      });

      it('calls the toast action', () => {
        expect(toast).toHaveBeenCalledWith(`${token.name} successfully revoked`);
      });
    });

    describe('when getting an error revoking token', () => {
      beforeEach(async () => {
        await createWrapper({ mutationResponse: mockErrorRevokeResponse });
        await submitTokenToRevoke();
      });

      it('displays the error message', () => {
        expect(toast).toHaveBeenCalledWith('could not revoke token');
      });
    });

    describe('when the revoke modal was closed', () => {
      beforeEach(async () => {
        const loadingResponse = new Promise(() => {});
        await createWrapper({ mutationResponse: loadingResponse });
        await submitTokenToRevoke();
      });

      it('reenables the button', async () => {
        expect(findPrimaryActionAttributes('loading')).toBe(true);
        expect(findRevokeBtn().attributes('disabled')).toBeDefined();

        await findModal().vm.$emit('hide');

        expect(findPrimaryActionAttributes('loading')).toBe(false);
        expect(findRevokeBtn().attributes('disabled')).toBeUndefined();
      });

      it('clears the token name input', async () => {
        expect(findInput().attributes('value')).toBe(token.name);

        await findModal().vm.$emit('hide');

        expect(findInput().attributes('value')).toBeUndefined();
      });
    });
  });
});
