import { mount } from '@vue/test-utils';

import SignInPage from '~/jira_connect/subscriptions/pages/sign_in.vue';
import SignInButton from '~/jira_connect/subscriptions/components/sign_in_button.vue';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import createStore from '~/jira_connect/subscriptions/store';

jest.mock('~/jira_connect/subscriptions/utils');

describe('SignInPage', () => {
  let wrapper;
  let store;

  const findSignInButton = () => wrapper.findComponent(SignInButton);
  const findSubscriptionsList = () => wrapper.findComponent(SubscriptionsList);

  const createComponent = ({ provide, props } = {}) => {
    store = createStore();

    wrapper = mount(SignInPage, {
      store,
      provide,
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    const mockUsersPath = '/test';
    describe.each`
      scenario                   | expectSubscriptionsList | signInButtonText
      ${'with subscriptions'}    | ${true}                 | ${SignInPage.i18n.signinButtonTextWithSubscriptions}
      ${'without subscriptions'} | ${false}                | ${SignInButton.i18n.defaultButtonText}
    `('$scenario', ({ expectSubscriptionsList, signInButtonText }) => {
      beforeEach(() => {
        createComponent({
          provide: {
            usersPath: mockUsersPath,
          },
          props: {
            hasSubscriptions: expectSubscriptionsList,
          },
        });
      });

      it(`renders sign in button with text ${signInButtonText}`, () => {
        expect(findSignInButton().text()).toMatchInterpolatedText(signInButtonText);
      });

      it('renders sign in button with `usersPath` prop', () => {
        expect(findSignInButton().props('usersPath')).toBe(mockUsersPath);
      });

      it(`${expectSubscriptionsList ? 'renders' : 'does not render'} subscriptions list`, () => {
        expect(findSubscriptionsList().exists()).toBe(expectSubscriptionsList);
      });
    });
  });
});
