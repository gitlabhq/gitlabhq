import { GlAlert, GlButton, GlModal, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import JiraConnectApp from '~/jira_connect/components/app.vue';
import createStore from '~/jira_connect/store';
import { SET_ALERT } from '~/jira_connect/store/mutation_types';
import { persistAlert } from '~/jira_connect/utils';
import { __ } from '~/locale';

jest.mock('~/jira_connect/api');

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertLink = () => findAlert().find(GlLink);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findHeader = () => wrapper.findByTestId('new-jira-connect-ui-heading');
  const findHeaderText = () => findHeader().text();

  const createComponent = ({ provide, mountFn = shallowMount } = {}) => {
    store = createStore();

    wrapper = extendedWrapper(
      mountFn(JiraConnectApp, {
        store,
        provide,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    it('renders new UI', () => {
      createComponent();

      expect(findHeader().exists()).toBe(true);
      expect(findHeaderText()).toBe('Linked namespaces');
    });

    describe('when user is not logged in', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            usersPath: '/users',
          },
        });
      });

      it('renders "Sign in" button', () => {
        expect(findGlButton().text()).toBe('Sign in to add namespaces');
        expect(findGlModal().exists()).toBe(false);
      });
    });

    describe('when user is logged in', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders "Add" button and modal', () => {
        expect(findGlButton().text()).toBe('Add namespace');
        expect(findGlModal().exists()).toBe(true);
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
          persistAlert({ message: 'error message' });
          createComponent();

          const alert = findAlert();

          expect(alert.exists()).toBe(true);
          expect(alert.html()).toContain('error message');
        });
      });
    });
  });
});
