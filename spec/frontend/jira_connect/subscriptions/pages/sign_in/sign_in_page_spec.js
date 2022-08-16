import { shallowMount } from '@vue/test-utils';

import SignInPage from '~/jira_connect/subscriptions/pages/sign_in/sign_in_page.vue';
import SignInGitlabCom from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_com.vue';
import SignInGitlabMultiversion from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/index.vue';
import createStore from '~/jira_connect/subscriptions/store';

describe('SignInPage', () => {
  let wrapper;
  let store;

  const findSignInGitlabCom = () => wrapper.findComponent(SignInGitlabCom);
  const findSignInGitabMultiversion = () => wrapper.findComponent(SignInGitlabMultiversion);

  const createComponent = ({
    props = {},
    jiraConnectOauthEnabled,
    jiraConnectOauthSelfManagedEnabled,
  } = {}) => {
    store = createStore();

    wrapper = shallowMount(SignInPage, {
      store,
      provide: {
        glFeatures: {
          jiraConnectOauth: jiraConnectOauthEnabled,
          jiraConnectOauthSelfManaged: jiraConnectOauthSelfManagedEnabled,
        },
      },
      propsData: { hasSubscriptions: false, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    jiraConnectOauthEnabled | jiraConnectOauthSelfManagedEnabled | shouldRenderDotCom | shouldRenderMultiversion
    ${false}                | ${false}                           | ${true}            | ${false}
    ${false}                | ${true}                            | ${true}            | ${false}
    ${true}                 | ${false}                           | ${true}            | ${false}
    ${true}                 | ${true}                            | ${false}           | ${true}
  `(
    'renders correct component when jiraConnectOauth is $jiraConnectOauthEnabled and jiraConnectOauthSelfManaged is $jiraConnectOauthSelfManagedEnabled',
    ({
      jiraConnectOauthEnabled,
      jiraConnectOauthSelfManagedEnabled,
      shouldRenderDotCom,
      shouldRenderMultiversion,
    }) => {
      createComponent({ jiraConnectOauthEnabled, jiraConnectOauthSelfManagedEnabled });

      expect(findSignInGitlabCom().exists()).toBe(shouldRenderDotCom);
      expect(findSignInGitabMultiversion().exists()).toBe(shouldRenderMultiversion);
    },
  );

  describe('when jiraConnectOauthSelfManaged is false', () => {
    beforeEach(() => {
      createComponent({ jiraConnectOauthSelfManaged: false, props: { hasSubscriptions: true } });
    });

    it('renders SignInGitlabCom with correct props', () => {
      expect(findSignInGitlabCom().props()).toEqual({ hasSubscriptions: true });
    });

    describe('when error event is emitted', () => {
      it('emits another error event', () => {
        findSignInGitlabCom().vm.$emit('error');
        expect(wrapper.emitted('error')).toHaveLength(1);
      });
    });

    describe('when sign-in-oauth event is emitted', () => {
      it('emits another sign-in-oauth event', () => {
        findSignInGitlabCom().vm.$emit('sign-in-oauth');
        expect(wrapper.emitted('sign-in-oauth')[0]).toEqual([]);
      });
    });
  });
});
