import { GlLink, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraConnectApp from '~/jira_connect/subscriptions/components/app.vue';
import SignInPage from '~/jira_connect/subscriptions/pages/sign_in/sign_in_page.vue';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions_page.vue';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import BrowserSupportAlert from '~/jira_connect/subscriptions/components/browser_support_alert.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE } from '~/jira_connect/subscriptions/constants';
import { retrieveAlert } from '~/jira_connect/subscriptions/utils';
import { __ } from '~/locale';
import AccessorUtilities from '~/lib/utils/accessor';
import * as api from '~/jira_connect/subscriptions/api';
import { mockSubscription } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils');

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const mockCurrentUser = { name: 'root' };

  const findAlert = () => wrapper.findByTestId('jira-connect-persisted-alert');
  const findJiraConnectApp = () => wrapper.findByTestId('jira-connect-app');
  const findAlertLink = () => findAlert().findComponent(GlLink);
  const findSignInPage = () => wrapper.findComponent(SignInPage);
  const findSubscriptionsPage = () => wrapper.findComponent(SubscriptionsPage);
  const findUserLink = () => wrapper.findComponent(UserLink);
  const findBrowserSupportAlert = () => wrapper.findComponent(BrowserSupportAlert);

  const createComponent = ({ provide, initialState = {} } = {}) => {
    store = createStore({ ...initialState, subscriptions: [mockSubscription] });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(JiraConnectApp, {
      store,
      provide,
      stubs: {
        GlSprintf,
      },
    });
  };

  describe('template', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'canUseCrypto').mockReturnValue(true);
    });

    it('renders UserLink component', () => {
      createComponent();

      const userLink = findUserLink();
      expect(userLink.exists()).toBe(true);
      expect(userLink.props()).toEqual({
        hasSubscriptions: true,
        user: null,
        userSignedIn: false,
      });
    });

    it('renders only Jira Connect app', () => {
      createComponent();

      expect(findBrowserSupportAlert().exists()).toBe(false);
      expect(findJiraConnectApp().exists()).toBe(true);
    });

    it('renders only BrowserSupportAlert when canUseCrypto is false', () => {
      jest.spyOn(AccessorUtilities, 'canUseCrypto').mockReturnValue(false);

      createComponent();

      expect(findBrowserSupportAlert().exists()).toBe(true);
      expect(findJiraConnectApp().exists()).toBe(false);
    });

    describe.each`
      scenario                   | currentUser        | shouldRenderSignInPage | shouldRenderSubscriptionsPage
      ${'user is not signed in'} | ${undefined}       | ${true}                | ${false}
      ${'user is signed in'}     | ${mockCurrentUser} | ${false}               | ${true}
    `(
      'when $scenario',
      ({ currentUser, shouldRenderSignInPage, shouldRenderSubscriptionsPage }) => {
        beforeEach(() => {
          createComponent({
            initialState: {
              currentUser,
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
      },
    );

    describe('when sign in page emits `error` event', () => {
      beforeEach(() => {
        createComponent();
        findSignInPage().vm.$emit('error');
      });

      it('displays alert', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain(I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE);
        expect(alert.props('variant')).toBe('danger');
      });
    });

    describe('when sign in page emits `sign-in-oauth` event', () => {
      const mockSubscriptionsPath = '/mockSubscriptionsPath';

      beforeEach(() => {
        jest.spyOn(api, 'fetchSubscriptions').mockResolvedValue({ data: { subscriptions: [] } });

        createComponent({
          initialState: {
            currentUser: mockCurrentUser,
          },
          provide: {
            subscriptionsPath: mockSubscriptionsPath,
          },
        });

        findSignInPage().vm.$emit('sign-in-oauth');
      });

      it('dispatches `fetchSubscriptions` action', () => {
        expect(store.dispatch).toHaveBeenCalledWith('fetchSubscriptions', mockSubscriptionsPath);
      });
    });

    describe('alert', () => {
      const mockAlertData = { message: 'error message' };

      describe.each`
        alertData        | expectAlert
        ${undefined}     | ${false}
        ${mockAlertData} | ${true}
      `('when retrieveAlert returns $alertData', ({ alertData, expectAlert }) => {
        beforeEach(() => {
          retrieveAlert.mockReturnValue(alertData);

          createComponent();
        });

        it(`${expectAlert ? 'renders' : 'does not render'} alert on mount`, () => {
          const alert = findAlert();

          expect(alert.exists()).toBe(expectAlert);
          if (expectAlert) {
            expect(alert.text()).toContain(mockAlertData.message);
          }
        });
      });

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
            expect(alert.text()).toContain(message);
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
        createComponent();

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
    });
  });
});
