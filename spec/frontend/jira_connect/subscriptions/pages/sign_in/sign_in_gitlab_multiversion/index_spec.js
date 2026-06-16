import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SignInGitlabMultiversion from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/index.vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';
import VersionSelectForm from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/version_select_form.vue';

import { updateInstallation, setApiBaseURL } from '~/jira_connect/subscriptions/api';
import { reloadPage, persistBaseUrl, retrieveBaseUrl } from '~/jira_connect/subscriptions/utils';
import {
  GITLAB_COM_BASE_PATH,
  I18N_UPDATE_INSTALLATION_ERROR_MESSAGE,
  FAILED_TO_UPDATE_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import createStore from '~/jira_connect/subscriptions/store';

jest.mock('~/jira_connect/subscriptions/api', () => {
  return {
    updateInstallation: jest.fn(),
    setApiBaseURL: jest.fn(),
  };
});
jest.mock('~/jira_connect/subscriptions/utils');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('SignInGitlabMultiversion', () => {
  let wrapper;
  let store;

  const mockBasePath = 'gitlab.mycompany.com';

  const findSignInOauthButton = () => wrapper.findComponent(SignInOauthButton);
  const findVersionSelectForm = () => wrapper.findComponent(VersionSelectForm);
  const findSubtitle = () => wrapper.findByTestId('subtitle');

  const createComponent = () => {
    store = createStore();
    jest.spyOn(store, 'commit');
    wrapper = shallowMountExtended(SignInGitlabMultiversion, { store });
  };

  describe('when version is not selected', () => {
    describe('VersionSelectForm', () => {
      it('renders version select form', () => {
        createComponent();

        expect(findVersionSelectForm().exists()).toBe(true);
      });

      describe('when form emits "submit" event', () => {
        it('updates the backend, then saves the baseUrl and reloads', async () => {
          updateInstallation.mockResolvedValue({});

          createComponent();

          findVersionSelectForm().vm.$emit('submit', mockBasePath);
          await nextTick();

          expect(updateInstallation).toHaveBeenCalled();
          expect(persistBaseUrl).toHaveBeenCalledWith(mockBasePath);
          expect(reloadPage).toHaveBeenCalled();
        });

        describe('when updateInstallation rejects', () => {
          it.each`
            scenario                           | rejectedValue                                             | expectedMessage
            ${'with a server `errors` field'}  | ${{ response: { data: { errors: 'Bad instance URL' } } }} | ${'Bad instance URL'}
            ${'with a server `message` field'} | ${{ response: { data: { message: 'Unreachable' } } }}     | ${'Unreachable'}
            ${'with no response body'}         | ${new Error('network')}                                   | ${I18N_UPDATE_INSTALLATION_ERROR_MESSAGE}
          `('commits SET_ALERT $scenario', async ({ rejectedValue, expectedMessage }) => {
            updateInstallation.mockRejectedValue(rejectedValue);

            createComponent();

            findVersionSelectForm().vm.$emit('submit', mockBasePath);
            await waitForPromises();

            expect(store.commit).toHaveBeenCalledWith(SET_ALERT, {
              message: expectedMessage,
              linkUrl: FAILED_TO_UPDATE_DOC_LINK,
              variant: 'danger',
            });
            expect(persistBaseUrl).not.toHaveBeenCalled();
            expect(reloadPage).not.toHaveBeenCalled();
          });

          it('reports the error to Sentry', async () => {
            const error = new Error('network');
            updateInstallation.mockRejectedValue(error);

            createComponent();

            findVersionSelectForm().vm.$emit('submit', mockBasePath);
            await waitForPromises();

            expect(Sentry.captureException).toHaveBeenCalledWith(error);
          });
        });
      });
    });
  });

  describe('when version is selected', () => {
    describe('when on self-managed', () => {
      beforeEach(() => {
        retrieveBaseUrl.mockReturnValue(mockBasePath);
        createComponent();
      });

      it('renders correct subtitle', () => {
        expect(findSubtitle().text()).toBe(SignInGitlabMultiversion.i18n.signInSubtitle);
      });

      it('renders sign in button', () => {
        expect(findSignInOauthButton().props('gitlabBasePath')).toBe(mockBasePath);
      });

      it('calls setApiBaseURL with correct params', () => {
        expect(setApiBaseURL).toHaveBeenCalledWith(mockBasePath);
      });
    });

    describe('when on GitLab.com', () => {
      beforeEach(() => {
        retrieveBaseUrl.mockReturnValue(GITLAB_COM_BASE_PATH);
        createComponent();
      });

      it('renders sign in button', () => {
        expect(findSignInOauthButton().props('gitlabBasePath')).toBe(GITLAB_COM_BASE_PATH);
      });

      it('does not call setApiBaseURL', () => {
        expect(setApiBaseURL).not.toHaveBeenCalled();
      });

      describe('when button emits `sign-in` event', () => {
        it('emits `sign-in-oauth` event', () => {
          const button = findSignInOauthButton();

          const mockUser = { name: 'test' };
          button.vm.$emit('sign-in', mockUser);

          expect(wrapper.emitted('sign-in-oauth')[0]).toEqual([mockUser]);
        });
      });

      describe('when button emits `error` event', () => {
        it('emits `error` event', () => {
          const button = findSignInOauthButton();
          button.vm.$emit('error');

          expect(wrapper.emitted('error')).toHaveLength(1);
        });
      });
    });
  });
});
