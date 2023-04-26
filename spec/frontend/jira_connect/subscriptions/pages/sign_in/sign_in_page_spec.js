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

  const createComponent = ({ props = {}, publicKeyStorageEnabled } = {}) => {
    store = createStore();

    wrapper = shallowMount(SignInPage, {
      store,
      propsData: {
        hasSubscriptions: false,
        publicKeyStorageEnabled,
        ...props,
      },
    });
  };

  it.each`
    publicKeyStorageEnabled | shouldRenderDotCom | shouldRenderMultiversion
    ${true}                 | ${false}           | ${true}
    ${false}                | ${true}            | ${false}
  `(
    'renders correct component when publicKeyStorageEnabled is $publicKeyStorageEnabled',
    ({ publicKeyStorageEnabled, shouldRenderDotCom, shouldRenderMultiversion }) => {
      createComponent({ publicKeyStorageEnabled });

      expect(findSignInGitlabCom().exists()).toBe(shouldRenderDotCom);
      expect(findSignInGitabMultiversion().exists()).toBe(shouldRenderMultiversion);
    },
  );
});
