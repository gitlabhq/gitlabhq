import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';
import {
  I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
  OAUTH_WINDOW_OPTIONS,
} from '~/jira_connect/subscriptions/constants';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatus from '~/lib/utils/http_status';
import AccessorUtilities from '~/lib/utils/accessor';

jest.mock('~/lib/utils/accessor');
jest.mock('~/jira_connect/subscriptions/utils');
jest.mock('~/jira_connect/subscriptions/pkce', () => ({
  createCodeVerifier: jest.fn().mockReturnValue('mock-verifier'),
  createCodeChallenge: jest.fn().mockResolvedValue('mock-challenge'),
}));

const mockOauthMetadata = {
  oauth_authorize_url: 'https://gitlab.com/mockOauth',
  oauth_token_url: 'https://gitlab.com/mockOauthToken',
  state: 'good-state',
};

describe('SignInOauthButton', () => {
  let wrapper;
  let mockAxios;

  const createComponent = ({ slots } = {}) => {
    wrapper = shallowMount(SignInOauthButton, {
      slots,
      provide: {
        oauthMetadata: mockOauthMetadata,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  const findButton = () => wrapper.findComponent(GlButton);

  it('displays a button', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().text()).toBe(I18N_DEFAULT_SIGN_IN_BUTTON_TEXT);
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
        `${mockOauthMetadata.oauth_authorize_url}?code_challenge=mock-challenge&code_challenge_method=S256`,
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
                  state: messageState,
                  code: '1234',
                },
              };
              window.dispatchEvent(new MessageEvent('message', mockEvent));
              await waitForPromises();
            });

            it('emits `error` event', () => {
              expect(wrapper.emitted('error')).toBeTruthy();
            });

            it('does not emit `sign-in` event', () => {
              expect(wrapper.emitted('sign-in')).toBeFalsy();
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
            state: mockOauthMetadata.state,
            code: '1234',
          },
        };

        describe('when API requests succeed', () => {
          beforeEach(async () => {
            jest.spyOn(axios, 'post');
            jest.spyOn(axios, 'get');
            mockAxios
              .onPost(mockOauthMetadata.oauth_token_url)
              .replyOnce(httpStatus.OK, { access_token: mockAccessToken });
            mockAxios.onGet('/api/v4/user').replyOnce(httpStatus.OK, mockUser);

            window.dispatchEvent(new MessageEvent('message', mockEvent));

            await waitForPromises();
          });

          it('executes POST request to Oauth token endpoint', () => {
            expect(axios.post).toHaveBeenCalledWith(mockOauthMetadata.oauth_token_url, {
              code: '1234',
              code_verifier: 'mock-verifier',
            });
          });

          it('executes GET request to fetch user data', () => {
            expect(axios.get).toHaveBeenCalledWith('/api/v4/user', {
              headers: { Authorization: `Bearer ${mockAccessToken}` },
            });
          });

          it('emits `sign-in` event with user data', () => {
            expect(wrapper.emitted('sign-in')[0]).toEqual([mockUser]);
          });
        });

        describe('when API requests fail', () => {
          beforeEach(async () => {
            jest.spyOn(axios, 'post');
            jest.spyOn(axios, 'get');
            mockAxios
              .onPost(mockOauthMetadata.oauth_token_url)
              .replyOnce(httpStatus.INTERNAL_SERVER_ERROR, { access_token: mockAccessToken });
            mockAxios.onGet('/api/v4/user').replyOnce(httpStatus.INTERNAL_SERVER_ERROR, mockUser);

            window.dispatchEvent(new MessageEvent('message', mockEvent));

            await waitForPromises();
          });

          it('emits `error` event', () => {
            expect(wrapper.emitted('error')).toBeTruthy();
          });

          it('does not emit `sign-in` event', () => {
            expect(wrapper.emitted('sign-in')).toBeFalsy();
          });

          it('sets `loading` prop of button to `false`', () => {
            expect(findButton().props('loading')).toBe(false);
          });
        });
      });
    });
  });
});
