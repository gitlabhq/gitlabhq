import { GlAlert, GlFormInputGroup, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import DependencyProxyApp from '~/packages_and_registries/dependency_proxy/app.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('DependencyProxyApp', () => {
  let wrapper;

  const provideDefaults = {
    groupPath: 'gitlab-org',
    dependencyProxyAvailable: true,
  };

  function createComponent({ provide = provideDefaults } = {}) {
    wrapper = shallowMountExtended(DependencyProxyApp, {
      provide,
      stubs: {
        GlFormInputGroup,
        GlFormGroup,
        GlSprintf,
      },
    });
  }

  const findProxyNotAvailableAlert = () => wrapper.findComponent(GlAlert);
  const findClipBoardButton = () => wrapper.findComponent(ClipboardButton);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findMainArea = () => wrapper.findByTestId('main-area');
  const findProxyCountText = () => wrapper.findByTestId('proxy-count');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the dependency proxy is not available', () => {
    beforeEach(() => {
      createComponent({ provide: { ...provideDefaults, dependencyProxyAvailable: false } });
    });

    it('renders an info alert', () => {
      expect(findProxyNotAvailableAlert().text()).toBe(
        DependencyProxyApp.i18n.proxyNotAvailableText,
      );
    });

    it('does not render the main area', () => {
      expect(findMainArea().exists()).toBe(false);
    });
  });

  describe('when the dependency proxy is available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the info alert', () => {
      expect(findProxyNotAvailableAlert().exists()).toBe(false);
    });

    it('renders the main area', () => {
      expect(findMainArea().exists()).toBe(true);
    });

    it('renders a form group with a label', () => {
      expect(findFormGroup().attributes('label')).toBe(DependencyProxyApp.i18n.proxyImagePrefix);
    });

    it('renders a form input group', () => {
      expect(findFormInputGroup().exists()).toBe(true);
    });

    it('form input group has a clipboard button', () => {
      expect(findClipBoardButton().exists()).toBe(true);
    });

    it('from group has a description with proxy count', () => {
      expect(findProxyCountText().text()).toBe('Contains 0 blobs of images (0 bytes)');
    });
  });
});
