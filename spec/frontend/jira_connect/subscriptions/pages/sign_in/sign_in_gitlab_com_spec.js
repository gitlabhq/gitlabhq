import { shallowMount } from '@vue/test-utils';

import SignInGitlabCom from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_com.vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { I18N_DEFAULT_SIGN_IN_BUTTON_TEXT } from '~/jira_connect/subscriptions/constants';

jest.mock('~/jira_connect/subscriptions/utils');

const defaultProvide = {
  oauthMetadata: {},
};

describe('SignInGitlabCom', () => {
  let wrapper;
  let store;

  const findSignInOauthButton = () => wrapper.findComponent(SignInOauthButton);
  const findSubscriptionsList = () => wrapper.findComponent(SubscriptionsList);

  const createComponent = ({ props } = {}) => {
    store = createStore();

    wrapper = shallowMount(SignInGitlabCom, {
      store,
      provide: {
        ...defaultProvide,
      },
      propsData: props,
      stubs: {
        SignInOauthButton,
      },
    });
  };

  describe('template', () => {
    describe.each`
      scenario                   | hasSubscriptions | signInButtonText
      ${'with subscriptions'}    | ${true}          | ${SignInGitlabCom.i18n.signInButtonTextWithSubscriptions}
      ${'without subscriptions'} | ${false}         | ${I18N_DEFAULT_SIGN_IN_BUTTON_TEXT}
    `('$scenario', ({ hasSubscriptions, signInButtonText }) => {
      beforeEach(() => {
        createComponent({
          props: {
            hasSubscriptions,
          },
        });
      });

      describe('oauth sign in button', () => {
        it('renders oauth sign in button', () => {
          const button = findSignInOauthButton();
          expect(button.text()).toMatchInterpolatedText(signInButtonText);
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

      it(`${hasSubscriptions ? 'renders' : 'does not render'} subscriptions list`, () => {
        createComponent({
          props: {
            hasSubscriptions,
          },
        });

        expect(findSubscriptionsList().exists()).toBe(hasSubscriptions);
      });
    });
  });
});
