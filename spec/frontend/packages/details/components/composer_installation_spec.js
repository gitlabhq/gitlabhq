import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { registryUrl as composerHelpPath } from 'jest/packages/details/mock_data';
import { composerPackage as packageEntity } from 'jest/packages/mock_data';
import ComposerInstallation from '~/packages/details/components/composer_installation.vue';
import InstallationTitle from '~/packages/details/components/installation_title.vue';

import { TrackingActions } from '~/packages/details/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ComposerInstallation', () => {
  let wrapper;
  let store;

  const composerRegistryIncludeStr = 'foo/registry';
  const composerPackageIncludeStr = 'foo/package';

  const createStore = (groupExists = true) => {
    store = new Vuex.Store({
      state: { packageEntity, composerHelpPath },
      getters: {
        composerRegistryInclude: () => composerRegistryIncludeStr,
        composerPackageInclude: () => composerPackageIncludeStr,
        groupExists: () => groupExists,
      },
    });
  };

  const findRootNode = () => wrapper.find('[data-testid="root-node"]');
  const findRegistryInclude = () => wrapper.find('[data-testid="registry-include"]');
  const findPackageInclude = () => wrapper.find('[data-testid="package-include"]');
  const findHelpText = () => wrapper.find('[data-testid="help-text"]');
  const findHelpLink = () => wrapper.find(GlLink);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMount(ComposerInstallation, {
      localVue,
      store,
      stubs: {
        GlSprintf,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('install command switch', () => {
    it('has the installation title component', () => {
      createStore();
      createComponent();

      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: 'composer',
        options: [{ value: 'composer', label: 'Show Composer commands' }],
      });
    });
  });

  describe('registry include command', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('uses code_instructions', () => {
      const registryIncludeCommand = findRegistryInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: composerRegistryIncludeStr,
        copyText: 'Copy registry include',
        trackingAction: TrackingActions.COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
      });
    });

    it('has the correct title', () => {
      expect(findRegistryInclude().props('label')).toBe('Add composer registry');
    });
  });

  describe('package include command', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('uses code_instructions', () => {
      const registryIncludeCommand = findPackageInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: composerPackageIncludeStr,
        copyText: 'Copy require package include',
        trackingAction: TrackingActions.COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
      });
    });

    it('has the correct title', () => {
      expect(findPackageInclude().props('label')).toBe('Install package version');
    });

    it('has the correct help text', () => {
      expect(findHelpText().text()).toBe(
        'For more information on Composer packages in GitLab, see the documentation.',
      );
      expect(findHelpLink().attributes()).toMatchObject({
        href: composerHelpPath,
        target: '_blank',
      });
    });
  });

  describe('root node', () => {
    it('is normally rendered', () => {
      createStore();
      createComponent();

      expect(findRootNode().exists()).toBe(true);
    });

    it('is not rendered when the group does not exist', () => {
      createStore(false);
      createComponent();

      expect(findRootNode().exists()).toBe(false);
    });
  });
});
