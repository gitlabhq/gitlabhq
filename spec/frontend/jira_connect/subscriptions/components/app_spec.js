import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraConnectApp from '~/jira_connect/subscriptions/components/app.vue';
import SignInPage from '~/jira_connect/subscriptions/pages/sign_in.vue';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions.vue';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE } from '~/jira_connect/subscriptions/constants';
import { __ } from '~/locale';
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

  const createComponent = ({ provide, mountFn = shallowMountExtended } = {}) => {
    store = createStore();

    wrapper = mountFn(JiraConnectApp, {
      store,
      provide,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
            subscriptions: [mockSubscription],
          },
        });
      });

      it(`${shouldRenderSignInPage ? 'renders' : 'does not render'} sign in page`, () => {
        expect(findSignInPage().exists()).toBe(shouldRenderSignInPage);
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
          subscriptions: [],
        },
      });

      const userLink = findUserLink();
      expect(userLink.exists()).toBe(true);
      expect(userLink.props()).toEqual({
        hasSubscriptions: false,
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
      createComponent({ mountFn: mountExtended });

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
    describe('when sign in page emits `sign-in-oauth` event', () => {
      const mockUser = { name: 'test' };
      beforeEach(async () => {
        createComponent({
          provide: {
            usersPath: '/mock',
            subscriptions: [],
          },
        });
        findSignInPage().vm.$emit('sign-in-oauth', mockUser);

        await nextTick();
      });

      it('hides sign in page and renders subscriptions page', () => {
        expect(findSignInPage().exists()).toBe(false);
        expect(findSubscriptionsPage().exists()).toBe(true);
      });

      it('sets correct UserLink props', () => {
        expect(findUserLink().props()).toMatchObject({
          user: mockUser,
          userSignedIn: true,
        });
      });
    });

    describe('when sign in page emits `error` event', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            usersPath: '/mock',
            subscriptions: [],
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
});
