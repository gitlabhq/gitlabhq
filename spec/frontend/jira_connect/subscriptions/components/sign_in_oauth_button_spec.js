import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue, { nextTick } from 'vue';

import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';
import {
  GITLAB_COM_BASE_PATH,
  I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
  I18N_OAUTH_LOCAL_NETWORK_ACCESS_TITLE,
  I18N_OAUTH_LOCAL_NETWORK_ACCESS_MESSAGE,
  OAUTH_LOCAL_NETWORK_ACCESS_DOC_LINK,
  OAUTH_WINDOW_OPTIONS,
} from '~/jira_connect/subscriptions/constants';
import waitForPromises from 'helpers/wait_for_promises';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  getCurrentUser,
  fetchOAuthApplicationId,
  fetchOAuthToken,
} from '~/jira_connect/subscriptions/api';
import { useJiraConnectSubscriptions } from '~/jira_connect/subscriptions/store';

Vue.use(PiniaVuePlugin);

jest.mock('~/lib/utils/accessor');
jest.mock('~/jira_connect/subscriptions/utils');
jest.mock('~/jira_connect/subscriptions/api');
jest.mock('~/jira_connect/subscriptions/pkce', () => ({
  createCodeVerifier: jest.fn().mockReturnValue('mock-verifier'),
  createCodeChallenge: jest.fn().mockResolvedValue('mock-challenge'),
}));

describe('SignInOauthButton', () => {
  let wrapper;
  let store;
  const mockOauthMetadata = {
    oauth_authorize_url: 'https://gitlab.com/mockOauth',
    oauth_token_path: 'https://gitlab.com/mockOauthToken',
    oauth_token_payload: {
      client_id: '543678901',
    },
    state: 'good-state',
  };
  const defaultProps = {
    gitlabBasePath: GITLAB_COM_BASE_PATH,
  };

  const createComponent = ({ slots, props } = {}) => {
    const pinia = createTestingPinia();
    store = useJiraConnectSubscriptions();

    wrapper = shallowMount(SignInOauthButton, {
      pinia,
      slots,
      provide: {
        oauthMetadata: mockOauthMetadata,
      },
      propsData: { ...defaultProps, ...props },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  const mockUserAgentBrands = (brands) => {
    Object.defineProperty(navigator, 'userAgentData', {
      value: brands === undefined ? undefined : { brands },
      configurable: true,
    });
  };

  afterEach(() => {
    mockUserAgentBrands(undefined);
  });
  describe('when `gitlabBasePath` is GitLab.com', () => {
    it('displays a button', () => {
      createComponent();

      expect(findButton().exists()).toBe(true);
      expect(findButton().text()).toBe(I18N_DEFAULT_SIGN_IN_BUTTON_TEXT);
      expect(findButton().props('category')).toBe('primary');
    });
  });

  describe('when `gitlabBasePath` is self-managed', () => {
    const mockBasePath = 'https://gitlab.mycompany.com';

    it('uses custom text for button', () => {
      createComponent({
        props: {
          gitlabBasePath: mockBasePath,
        },
      });

      expect(findButton().text()).toBe(`Sign in to ${mockBasePath}`);
    });

    describe('on click', () => {
      const mockClientId = '798412381';

      beforeEach(async () => {
        fetchOAuthApplicationId.mockReturnValue({ data: { application_id: mockClientId } });
        jest.spyOn(window, 'open').mockReturnValue();
        createComponent({
          props: {
            gitlabBasePath: mockBasePath,
          },
        });

        findButton().vm.$emit('click');

        await nextTick();
      });

      it('calls `window.open` with correct arguments', () => {
        expect(window.open).toHaveBeenCalledWith(
          `${mockBasePath}/mockOauth?code_challenge=mock-challenge&code_challenge_method=S256&client_id=${mockClientId}`,
          I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
          OAUTH_WINDOW_OPTIONS,
        );
      });
    });

    describe('when `gitlabBasePath` is hosted at a subpath', () => {
      const mockClientId = '798412381';
      const mockSubpathBasePath = 'https://gitlab.mycompany.com/gitlab';
      const expectedAuthorizeUrl = `${mockSubpathBasePath}/oauth/authorize?code_challenge=mock-challenge&code_challenge_method=S256&client_id=${mockClientId}`;
      const buildOauthMetadata = (oauthAuthorizeUrl) => ({
        ...mockOauthMetadata,
        oauth_authorize_url: oauthAuthorizeUrl,
      });

      const triggerSignIn = async (oauthMetadata, basePath) => {
        fetchOAuthApplicationId.mockReturnValue({ data: { application_id: mockClientId } });
        jest.spyOn(window, 'open').mockReturnValue();

        const pinia = createTestingPinia();
        store = useJiraConnectSubscriptions();
        wrapper = shallowMount(SignInOauthButton, {
          pinia,
          provide: { oauthMetadata },
          propsData: { gitlabBasePath: basePath },
        });

        findButton().vm.$emit('click');
        await nextTick();
        await waitForPromises();
      };

      it('does not duplicate the subpath when the backend URL already includes it', async () => {
        await triggerSignIn(
          buildOauthMetadata('https://gitlab.mycompany.com/gitlab/oauth/authorize'),
          mockSubpathBasePath,
        );

        expect(window.open).toHaveBeenCalledWith(
          expectedAuthorizeUrl,
          I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
          OAUTH_WINDOW_OPTIONS,
        );
      });

      it('prepends the subpath when the backend URL is missing it', async () => {
        await triggerSignIn(
          buildOauthMetadata('https://gitlab.com/oauth/authorize'),
          mockSubpathBasePath,
        );

        expect(window.open).toHaveBeenCalledWith(
          expectedAuthorizeUrl,
          I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
          OAUTH_WINDOW_OPTIONS,
        );
      });

      it('strips a trailing slash from the base path to avoid double slashes', async () => {
        await triggerSignIn(
          buildOauthMetadata('https://gitlab.com/oauth/authorize'),
          `${mockSubpathBasePath}/`,
        );

        expect(window.open).toHaveBeenCalledWith(
          expectedAuthorizeUrl,
          I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
          OAUTH_WINDOW_OPTIONS,
        );
      });

      it('handles a trailing slash on the base path when the backend URL already includes the subpath', async () => {
        await triggerSignIn(
          buildOauthMetadata('https://gitlab.mycompany.com/gitlab/oauth/authorize'),
          `${mockSubpathBasePath}/`,
        );

        expect(window.open).toHaveBeenCalledWith(
          expectedAuthorizeUrl,
          I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
          OAUTH_WINDOW_OPTIONS,
        );
      });
    });
  });

  it.each`
    scenario                            | cryptoAvailable
    ${'when crypto API is available'}   | ${true}
    ${'when crypto API is unavailable'} | ${false}
  `('$scenario when canUseCrypto returns $cryptoAvailable', ({ cryptoAvailable }) => {
    AccessorUtilities.canUseCrypto = jest.fn().mockReturnValue(cryptoAvailable);
    createComponent();

    expect(findButton().props('disabled')).toBe(!cryptoAvailable);
  });

  describe('on click', () => {
    beforeEach(async () => {
      jest.spyOn(window, 'open').mockReturnValue();
      createComponent();

      findButton().vm.$emit('click');

      await nextTick();
    });

    it('sets `loading` prop of button to `true`', () => {
      expect(findButton().props('loading')).toBe(true);
    });

    it('calls `window.open` with correct arguments', () => {
      expect(window.open).toHaveBeenCalledWith(
        `${mockOauthMetadata.oauth_authorize_url}?code_challenge=mock-challenge&code_challenge_method=S256&client_id=${mockOauthMetadata.oauth_token_payload.client_id}`,
        I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
        OAUTH_WINDOW_OPTIONS,
      );
    });

    it('sets the `codeVerifier` internal state', () => {
      expect(wrapper.vm.codeVerifier).toBe('mock-verifier');
    });

    describe('on window message event', () => {
      describe('when window message properties are corrupted', () => {
        describe.each`
          origin           | state                      | messageOrigin    | messageState
          ${window.origin} | ${mockOauthMetadata.state} | ${'bad-origin'}  | ${mockOauthMetadata.state}
          ${window.origin} | ${mockOauthMetadata.state} | ${window.origin} | ${'bad-state'}
        `(
          'when message is [state=$messageState, origin=$messageOrigin]',
          ({ messageOrigin, messageState }) => {
            beforeEach(async () => {
              const mockEvent = {
                origin: messageOrigin,
                data: {
                  type: 'jiraConnectOauthCallback',
                  state: messageState,
                  code: '1234',
                },
              };
              window.dispatchEvent(new MessageEvent('message', mockEvent));
              await waitForPromises();
            });

            it('does not emit `sign-in` event', () => {
              expect(wrapper.emitted('sign-in')).toBeUndefined();
            });

            it('sets `loading` prop of button to `false`', () => {
              expect(findButton().props('loading')).toBe(false);
            });
          },
        );
      });

      describe('when window message properties are valid', () => {
        const mockAccessToken = '5678';
        const mockUser = { name: 'test user' };
        const mockEvent = {
          origin: window.origin,
          data: {
            type: 'jiraConnectOauthCallback',
            state: mockOauthMetadata.state,
            code: '1234',
          },
        };

        describe('when API requests succeed', () => {
          beforeEach(async () => {
            fetchOAuthToken.mockResolvedValue({ data: { access_token: mockAccessToken } });
            getCurrentUser.mockResolvedValue({ data: mockUser });

            window.dispatchEvent(new MessageEvent('message', mockEvent));

            await waitForPromises();
          });

          it('executes POST request to Oauth token endpoint', () => {
            expect(fetchOAuthToken).toHaveBeenCalledWith(mockOauthMetadata.oauth_token_path, {
              code: '1234',
              code_verifier: 'mock-verifier',
              client_id: mockOauthMetadata.oauth_token_payload.client_id,
            });
          });

          it('calls loadCurrentUser action', () => {
            expect(store.loadCurrentUser).toHaveBeenCalledWith(mockAccessToken);
          });

          it('calls setAccessToken action with correct access token', () => {
            expect(store.setAccessToken).toHaveBeenCalledWith(mockAccessToken);
          });

          it('emits `sign-in` event with user data', () => {
            expect(wrapper.emitted('sign-in')).toHaveLength(1);
          });
        });

        describe('when API requests fail', () => {
          beforeEach(async () => {
            fetchOAuthToken.mockRejectedValue();

            window.dispatchEvent(new MessageEvent('message', mockEvent));

            await waitForPromises();
          });

          it('emits `error` event', () => {
            expect(wrapper.emitted('error')[0]).toEqual([]);
          });

          it('does not emit `sign-in` event', () => {
            expect(wrapper.emitted('sign-in')).toBeUndefined();
          });

          it('sets `loading` prop of button to `false`', () => {
            expect(findButton().props('loading')).toBe(false);
          });
        });

        describe('when token request fails with a network error on a self-managed instance', () => {
          const mockBasePath = 'https://gitlab.mycompany.com';

          const triggerNetworkErrorOnSelfManaged = async () => {
            createComponent({ props: { gitlabBasePath: mockBasePath } });
            // axios surfaces a network failure (e.g. Chromium LNA blocking
            // the request before any preflight) as an error with no `response`.
            fetchOAuthToken.mockRejectedValue({ message: 'Network Error' });

            findButton().vm.$emit('click');
            await nextTick();

            window.dispatchEvent(new MessageEvent('message', mockEvent));
            await waitForPromises();
          };

          describe('and the browser is Chromium 142+', () => {
            beforeEach(async () => {
              mockUserAgentBrands([{ brand: 'Chromium', version: '142' }]);
              await triggerNetworkErrorOnSelfManaged();
            });

            it('sets a Local Network Access alert', () => {
              expect(store.setAlert).toHaveBeenCalledWith({
                linkUrl: OAUTH_LOCAL_NETWORK_ACCESS_DOC_LINK,
                title: I18N_OAUTH_LOCAL_NETWORK_ACCESS_TITLE,
                message: I18N_OAUTH_LOCAL_NETWORK_ACCESS_MESSAGE,
                variant: 'danger',
              });
            });

            it('does not emit the generic `error` event', () => {
              expect(wrapper.emitted('error')).toBeUndefined();
            });
          });

          describe('and the browser is Chromium older than 142', () => {
            beforeEach(async () => {
              mockUserAgentBrands([{ brand: 'Chromium', version: '141' }]);
              await triggerNetworkErrorOnSelfManaged();
            });

            it('emits the generic `error` event and does not set the LNA alert', () => {
              expect(wrapper.emitted('error')[0]).toEqual([]);
              expect(store.setAlert).not.toHaveBeenCalledWith(
                expect.objectContaining({ title: I18N_OAUTH_LOCAL_NETWORK_ACCESS_TITLE }),
              );
            });
          });

          describe('and the browser is not Chromium-based (no UA Client Hints)', () => {
            beforeEach(async () => {
              mockUserAgentBrands(undefined);
              await triggerNetworkErrorOnSelfManaged();
            });

            it('emits the generic `error` event and does not set the LNA alert', () => {
              expect(wrapper.emitted('error')[0]).toEqual([]);
              expect(store.setAlert).not.toHaveBeenCalledWith(
                expect.objectContaining({ title: I18N_OAUTH_LOCAL_NETWORK_ACCESS_TITLE }),
              );
            });
          });
        });

        describe('when token request fails with a network error on GitLab.com', () => {
          beforeEach(async () => {
            mockUserAgentBrands([{ brand: 'Chromium', version: '142' }]);
            fetchOAuthToken.mockRejectedValue({ message: 'Network Error' });

            window.dispatchEvent(new MessageEvent('message', mockEvent));
            await waitForPromises();
          });

          it('emits the generic `error` event and does not set the LNA alert', () => {
            expect(wrapper.emitted('error')[0]).toEqual([]);
            expect(store.setAlert).not.toHaveBeenCalledWith(
              expect.objectContaining({ title: I18N_OAUTH_LOCAL_NETWORK_ACCESS_TITLE }),
            );
          });
        });
      });
    });
  });

  describe('when `category` prop is set', () => {
    it('sets the `category` prop on the GlButton', () => {
      createComponent({ props: { category: 'tertiary' } });
      expect(findButton().props('category')).toBe('tertiary');
    });
  });
});
