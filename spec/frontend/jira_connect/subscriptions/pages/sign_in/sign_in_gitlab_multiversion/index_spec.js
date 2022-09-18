import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import SignInGitlabMultiversion from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/index.vue';
import VersionSelectForm from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/version_select_form.vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';

import { updateInstallation } from '~/jira_connect/subscriptions/api';
import { reloadPage, persistBaseUrl, retrieveBaseUrl } from '~/jira_connect/subscriptions/utils';

jest.mock('~/jira_connect/subscriptions/api', () => {
  return {
    updateInstallation: jest.fn(),
    setApiBaseURL: jest.fn(),
  };
});
jest.mock('~/jira_connect/subscriptions/utils');

describe('SignInGitlabMultiversion', () => {
  let wrapper;

  const mockBasePath = 'gitlab.mycompany.com';

  const findVersionSelectForm = () => wrapper.findComponent(VersionSelectForm);
  const findSignInOauthButton = () => wrapper.findComponent(SignInOauthButton);
  const findSubtitle = () => wrapper.findByTestId('subtitle');

  const createComponent = () => {
    wrapper = shallowMountExtended(SignInGitlabMultiversion);
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
      });
    });
  });

  describe('when version is selected', () => {
    beforeEach(() => {
      retrieveBaseUrl.mockReturnValue(mockBasePath);
      createComponent();
    });

    describe('sign in button', () => {
      it('renders sign in button', () => {
        expect(findSignInOauthButton().exists()).toBe(true);
        expect(findSignInOauthButton().props('gitlabBasePath')).toBe(mockBasePath);
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

    it('renders correct subtitle', () => {
      expect(findSubtitle().text()).toBe(SignInGitlabMultiversion.i18n.signInSubtitle);
    });
  });
});
