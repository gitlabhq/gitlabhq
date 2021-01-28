import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { GlAlert, GlButton, GlModal } from '@gitlab/ui';

import JiraConnectApp from '~/jira_connect/components/app.vue';
import createStore from '~/jira_connect/store';
import { SET_ERROR_MESSAGE } from '~/jira_connect/store/mutation_types';

jest.mock('~/jira_connect/api');

describe('JiraConnectApp', () => {
  let wrapper;
  let store;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findHeader = () => wrapper.findByTestId('new-jira-connect-ui-heading');
  const findHeaderText = () => findHeader().text();

  const createComponent = (options = {}) => {
    store = createStore();

    wrapper = extendedWrapper(
      shallowMount(JiraConnectApp, {
        store,
        provide: {
          glFeatures: { newJiraConnectUi: true },
        },
        ...options,
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
            glFeatures: { newJiraConnectUi: true },
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

    describe('newJiraConnectUi is false', () => {
      it('does not render new UI', () => {
        createComponent({
          provide: {
            glFeatures: { newJiraConnectUi: false },
          },
        });

        expect(findHeader().exists()).toBe(false);
      });
    });

    it.each`
      errorMessage    | errorShouldRender
      ${'Test error'} | ${true}
      ${''}           | ${false}
      ${undefined}    | ${false}
    `(
      'renders correct alert when errorMessage is `$errorMessage`',
      async ({ errorMessage, errorShouldRender }) => {
        createComponent();

        store.commit(SET_ERROR_MESSAGE, errorMessage);
        await wrapper.vm.$nextTick();

        expect(findAlert().exists()).toBe(errorShouldRender);
        if (errorShouldRender) {
          expect(findAlert().isVisible()).toBe(errorShouldRender);
          expect(findAlert().html()).toContain(errorMessage);
        }
      },
    );
  });
});
