import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import ComposerInstallation from '~/packages_and_registries/package_registry/components/details/composer_installation.vue';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
  TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
  PACKAGE_TYPE_COMPOSER,
  COMPOSER_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_COMPOSER };

describe('ComposerInstallation', () => {
  let wrapper;

  const findRootNode = () => wrapper.findByTestId('root-node');
  const findRegistryInclude = () => wrapper.findByTestId('registry-include');
  const findPackageInclude = () => wrapper.findByTestId('package-include');
  const findHelpText = () => wrapper.findByTestId('help-text');
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent(groupListUrl = 'groupListUrl') {
    wrapper = shallowMountExtended(ComposerInstallation, {
      provide: {
        groupListUrl,
      },
      propsData: { packageEntity },
      stubs: {
        GlSprintf,
      },
    });
  }

  describe('install command switch', () => {
    it('has the installation title component', () => {
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
      createComponent();
    });

    it('uses code_instructions', () => {
      const registryIncludeCommand = findRegistryInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: `composer config repositories.${packageEntity.composerConfigRepositoryUrl} '{"type": "composer", "url": "${packageEntity.composerUrl}"}'`,
        copyText: 'Copy registry include',
        trackingAction: TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
      });
    });

    it('has the correct title', () => {
      expect(findRegistryInclude().props('label')).toBe('Add composer registry');
    });
  });

  describe('package include command', () => {
    beforeEach(() => {
      createComponent();
    });

    it('uses code_instructions', () => {
      const registryIncludeCommand = findPackageInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: 'composer req @gitlab-org/package-15:1.0.0',
        copyText: 'Copy require package include',
        trackingAction: TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
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
        href: COMPOSER_HELP_PATH,
        target: '_blank',
      });
    });
  });

  describe('root node', () => {
    it('is normally rendered', () => {
      createComponent();

      expect(findRootNode().exists()).toBe(true);
    });

    it('is not rendered when the group does not exist', () => {
      createComponent('');

      expect(findRootNode().exists()).toBe(false);
    });
  });
});
