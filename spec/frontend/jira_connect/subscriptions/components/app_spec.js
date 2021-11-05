import { GlAlert, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import JiraConnectApp from '~/jira_connect/subscriptions/components/app.vue';
import AddNamespaceButton from '~/jira_connect/subscriptions/components/add_namespace_button.vue';
import SignInButton from '~/jira_connect/subscriptions/components/sign_in_button.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';
import { __ } from '~/locale';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  retrieveAlert: jest.fn().mockReturnValue({ message: 'error message' }),
}));

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertLink = () => findAlert().findComponent(GlLink);
  const findSignInButton = () => wrapper.findComponent(SignInButton);
  const findAddNamespaceButton = () => wrapper.findComponent(AddNamespaceButton);

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
      scenario                   | usersPath    | expectSignInButton | expectNamespaceButton
      ${'user is not signed in'} | ${'/users'}  | ${true}            | ${false}
      ${'user is signed in'}     | ${undefined} | ${false}           | ${true}
    `('when $scenario', ({ usersPath, expectSignInButton, expectNamespaceButton }) => {
      beforeEach(() => {
        createComponent({
          provide: {
            usersPath,
          },
        });
      });

      it('renders sign in button as expected', () => {
        expect(findSignInButton().exists()).toBe(expectSignInButton);
      });

      it('renders "Add Namespace" button as expected', () => {
        expect(findAddNamespaceButton().exists()).toBe(expectNamespaceButton);
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
          await wrapper.vm.$nextTick();

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
        await wrapper.vm.$nextTick();

        findAlert().vm.$emit('dismiss');
        await wrapper.vm.$nextTick();

        expect(findAlert().exists()).toBe(false);
      });

      it('renders link when `linkUrl` is set', async () => {
        createComponent({ mountFn: mount });

        store.commit(SET_ALERT, {
          message: __('test message %{linkStart}test link%{linkEnd}'),
          linkUrl: 'https://gitlab.com',
        });
        await wrapper.vm.$nextTick();

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
});
