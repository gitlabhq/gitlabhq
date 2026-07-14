import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue from 'vue';

import SignInPage from '~/jira_connect/subscriptions/pages/sign_in/sign_in_page.vue';
import SignInGitlabCom from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_com.vue';
import SignInGitlabMultiversion from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/index.vue';

Vue.use(PiniaVuePlugin);

describe('SignInPage', () => {
  let wrapper;

  const findSignInGitlabCom = () => wrapper.findComponent(SignInGitlabCom);
  const findSignInGitabMultiversion = () => wrapper.findComponent(SignInGitlabMultiversion);

  const createComponent = ({ props = {}, publicKeyStorageEnabled } = {}) => {
    const pinia = createTestingPinia();

    wrapper = shallowMount(SignInPage, {
      pinia,
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
