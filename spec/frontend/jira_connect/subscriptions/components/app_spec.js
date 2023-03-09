import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraConnectApp from '~/jira_connect/subscriptions/components/app.vue';
import SignInPage from '~/jira_connect/subscriptions/pages/sign_in/sign_in_page.vue';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions_page.vue';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import BrowserSupportAlert from '~/jira_connect/subscriptions/components/browser_support_alert.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE } from '~/jira_connect/subscriptions/constants';
import { __ } from '~/locale';
import AccessorUtilities from '~/lib/utils/accessor';
import * as api from '~/jira_connect/subscriptions/api';
import { mockSubscription } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  retrieveAlert: jest.fn().mockReturnValue({ message: 'error message' }),
  getGitlabSignInURL: jest.fn(),
}));

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const findAlert = () => wrapper.findByTestId('jira-connect-persisted-alert');
  const findAlertLink = () => findAlert().findComponent(GlLink);
  const findSignInPage = () => wrapper.findComponent(SignInPage);
  const findSubscriptionsPage = () => wrapper.findComponent(SubscriptionsPage);
  const findUserLink = () => wrapper.findComponent(UserLink);
  const findBrowserSupportAlert = () => wrapper.findComponent(BrowserSupportAlert);

  const createComponent = ({ provide, mountFn = shallowMountExtended, initialState = {} } = {}) => {
    store = createStore({ ...initialState, subscriptions: [mockSubscription] });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = mountFn(JiraConnectApp, {
      store,
      provide,
    });
  };

  describe('template', () => {
    describe.each`
      scenario                   | usersPath    | shouldRenderSignInPage | shouldRenderSubscriptionsPage
      ${'user is not signed in'} | ${'/users'}  | ${true}                | ${false}
      ${'user is signed in'}     | ${undefined} | ${false}               | ${true}
    `('when $scenario', ({ usersPath, shouldRenderSignInPage, shouldRenderSubscriptionsPage }) => {
      beforeEach(() => {
        createComponent({
          provide: {
            usersPath,
          },
        });
      });

      it(`${shouldRenderSignInPage ? 'renders' : 'does not render'} sign in page`, () => {
        expect(findSignInPage().isVisible()).toBe(shouldRenderSignInPage);
        if (shouldRenderSignInPage) {
          expect(findSignInPage().props('hasSubscriptions')).toBe(true);
        }
      });

      it(`${
        shouldRenderSubscriptionsPage ? 'renders' : 'does not render'
      } subscriptions page`, () => {
        expect(findSubscriptionsPage().exists()).toBe(shouldRenderSubscriptionsPage);
        if (shouldRenderSubscriptionsPage) {
          expect(findSubscriptionsPage().props('hasSubscriptions')).toBe(true);
        }
      });
    });

    it('renders UserLink component', () => {
      createComponent({
        provide: {
          usersPath: '/user',
        },
      });

      const userLink = findUserLink();
      expect(userLink.exists()).toBe(true);
      expect(userLink.props()).toEqual({
        hasSubscriptions: true,
        user: null,
        userSignedIn: false,
      });
    });
  });

  describe('alert', () => {
    it.each`
      message          | variant      | alertShouldRender
      ${'Test error'}  | ${'danger'}  | ${true}
      ${'Test notice'} | ${'info'}    | ${true}
      ${''}            | ${undefined} | ${false}
      ${undefined}     | ${undefined} | ${false}
    `(
      'renders correct alert when message is `$message` and variant is `$variant`',
      async ({ message, alertShouldRender, variant }) => {
        createComponent();

        store.commit(SET_ALERT, { message, variant });
        await nextTick();

        const alert = findAlert();

        expect(alert.exists()).toBe(alertShouldRender);
        if (alertShouldRender) {
          expect(alert.isVisible()).toBe(alertShouldRender);
          expect(alert.html()).toContain(message);
          expect(alert.props('variant')).toBe(variant);
          expect(findAlertLink().exists()).toBe(false);
        }
      },
    );

    it('hides alert on @dismiss event', async () => {
      createComponent();

      store.commit(SET_ALERT, { message: 'test message' });
      await nextTick();

      findAlert().vm.$emit('dismiss');
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });

    it('renders link when `linkUrl` is set', async () => {
      createComponent({ provide: { usersPath: '' }, mountFn: mountExtended });

      store.commit(SET_ALERT, {
        message: __('test message %{linkStart}test link%{linkEnd}'),
        linkUrl: 'https://gitlab.com',
      });
      await nextTick();

      const alertLink = findAlertLink();

      expect(alertLink.exists()).toBe(true);
      expect(alertLink.text()).toContain('test link');
      expect(alertLink.attributes('href')).toBe('https://gitlab.com');
    });

    describe('when alert is set in localStoage', () => {
      it('renders alert on mount', () => {
        createComponent();

        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.html()).toContain('error message');
      });
    });
  });

  describe('when user signed out', () => {
    describe('when sign in page emits `error` event', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            usersPath: '/mock',
          },
        });
        findSignInPage().vm.$emit('error');

        await nextTick();
      });

      it('displays alert', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.html()).toContain(I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE);
        expect(alert.props('variant')).toBe('danger');
      });
    });
  });

  describe.each`
    jiraConnectOauthEnabled | canUseCrypto | shouldShowAlert
    ${false}                | ${false}     | ${false}
    ${false}                | ${true}      | ${false}
    ${true}                 | ${false}     | ${true}
    ${true}                 | ${true}      | ${false}
  `(
    'when `jiraConnectOauth` feature flag is $jiraConnectOauthEnabled and `AccessorUtilities.canUseCrypto` returns $canUseCrypto',
    ({ jiraConnectOauthEnabled, canUseCrypto, shouldShowAlert }) => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseCrypto').mockReturnValue(canUseCrypto);

        createComponent({ provide: { glFeatures: { jiraConnectOauth: jiraConnectOauthEnabled } } });
      });

      it(`does ${shouldShowAlert ? '' : 'not'} render BrowserSupportAlert component`, () => {
        expect(findBrowserSupportAlert().exists()).toBe(shouldShowAlert);
      });

      it(`does ${!shouldShowAlert ? '' : 'not'} render the main Jira Connect app template`, () => {
        expect(wrapper.findByTestId('jira-connect-app').exists()).toBe(!shouldShowAlert);
      });
    },
  );

  describe('when `jiraConnectOauth` feature flag is enabled', () => {
    const mockSubscriptionsPath = '/mockSubscriptionsPath';

    beforeEach(async () => {
      jest.spyOn(api, 'fetchSubscriptions').mockResolvedValue({ data: { subscriptions: [] } });
      jest.spyOn(AccessorUtilities, 'canUseCrypto').mockReturnValue(true);

      createComponent({
        initialState: {
          currentUser: { name: 'root' },
        },
        provide: {
          glFeatures: { jiraConnectOauth: true },
          subscriptionsPath: mockSubscriptionsPath,
        },
      });

      findSignInPage().vm.$emit('sign-in-oauth');
      await nextTick();
    });

    describe('when oauth button emits `sign-in-oauth` event', () => {
      it('dispatches `fetchSubscriptions` action', () => {
        expect(store.dispatch).toHaveBeenCalledWith('fetchSubscriptions', mockSubscriptionsPath);
      });
    });
  });
});
