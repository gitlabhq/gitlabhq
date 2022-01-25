import { GlAlert, GlLink, GlEmptyState } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import JiraConnectApp from '~/jira_connect/subscriptions/components/app.vue';
import AddNamespaceButton from '~/jira_connect/subscriptions/components/add_namespace_button.vue';
import SignInButton from '~/jira_connect/subscriptions/components/sign_in_button.vue';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { __ } from '~/locale';
import { mockSubscription } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  retrieveAlert: jest.fn().mockReturnValue({ message: 'error message' }),
  getGitlabSignInURL: jest.fn(),
}));

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertLink = () => findAlert().findComponent(GlLink);
  const findSignInButton = () => wrapper.findComponent(SignInButton);
  const findAddNamespaceButton = () => wrapper.findComponent(AddNamespaceButton);
  const findSubscriptionsList = () => wrapper.findComponent(SubscriptionsList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ provide, mountFn = shallowMount } = {}) => {
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
      scenario                                         | usersPath    | subscriptions         | expectSignInButton | expectEmptyState | expectNamespaceButton | expectSubscriptionsList
      ${'user is not signed in with subscriptions'}    | ${'/users'}  | ${[mockSubscription]} | ${true}            | ${false}         | ${false}              | ${true}
      ${'user is not signed in without subscriptions'} | ${'/users'}  | ${undefined}          | ${true}            | ${false}         | ${false}              | ${false}
      ${'user is signed in with subscriptions'}        | ${undefined} | ${[mockSubscription]} | ${false}           | ${false}         | ${true}               | ${true}
      ${'user is signed in without subscriptions'}     | ${undefined} | ${undefined}          | ${false}           | ${true}          | ${false}              | ${false}
    `(
      'when $scenario',
      ({
        usersPath,
        expectSignInButton,
        subscriptions,
        expectEmptyState,
        expectNamespaceButton,
        expectSubscriptionsList,
      }) => {
        beforeEach(() => {
          createComponent({
            provide: {
              usersPath,
              subscriptions,
            },
          });
        });

        it(`${expectSignInButton ? 'renders' : 'does not render'} sign in button`, () => {
          expect(findSignInButton().exists()).toBe(expectSignInButton);
        });

        it(`${expectEmptyState ? 'renders' : 'does not render'} empty state`, () => {
          expect(findEmptyState().exists()).toBe(expectEmptyState);
        });

        it(`${
          expectNamespaceButton ? 'renders' : 'does not render'
        } button to add namespace`, () => {
          expect(findAddNamespaceButton().exists()).toBe(expectNamespaceButton);
        });

        it(`${expectSubscriptionsList ? 'renders' : 'does not render'} subscriptions list`, () => {
          expect(findSubscriptionsList().exists()).toBe(expectSubscriptionsList);
        });
      },
    );

    it('renders UserLink component', () => {
      createComponent({
        provide: {
          usersPath: '/user',
          subscriptions: [],
        },
      });

      const userLink = wrapper.findComponent(UserLink);
      expect(userLink.exists()).toBe(true);
      expect(userLink.props()).toEqual({
        hasSubscriptions: false,
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
      createComponent({ mountFn: mount });

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
});
