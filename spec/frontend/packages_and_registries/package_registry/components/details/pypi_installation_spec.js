import { mountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import InstallationMethod from '~/packages_and_registries/package_registry/components/details/installation_method.vue';
import PypiInstallation from '~/packages_and_registries/package_registry/components/details/pypi_installation.vue';
import {
  PERSONAL_ACCESS_TOKEN_HELP_URL,
  PACKAGE_TYPE_PYPI,
  TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
  PYPI_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_PYPI };

describe('PypiInstallation', () => {
  let wrapper;

  const pipCommandStr = `pip install @gitlab-org/package-15 --index-url ${packageEntity.pypiUrl}`;
  const pypiSetupStr = `[gitlab]
repository = ${packageEntity.pypiSetupUrl}
username = __token__
password = <your personal access token>`;

  const pipCommand = () => wrapper.findByTestId('pip-command');
  const setupInstruction = () => wrapper.findByTestId('pypi-setup-content');

  const findAccessTokenLink = () => wrapper.findByTestId('access-token-link');
  const findInstallationMethod = () => wrapper.findComponent(InstallationMethod);
  const findSetupDocsLink = () => wrapper.findByTestId('pypi-docs-link');

  function createComponent(props = {}) {
    wrapper = mountExtended(PypiInstallation, {
      propsData: {
        packageEntity: {
          ...packageEntity,
          ...props,
        },
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  describe('install command switch', () => {
    it('does not show the installation method component', () => {
      expect(findInstallationMethod().exists()).toBe(false);
    });
  });

  describe('installation commands', () => {
    it('renders the correct pip command', () => {
      expect(pipCommand().props()).toMatchObject({
        instruction: pipCommandStr,
        trackingAction: TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct setup block', () => {
      expect(setupInstruction().props()).toMatchObject({
        instruction: pypiSetupStr,
        multiline: true,
        trackingAction: TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
      });
    });

    it('has a link to personal access token docs', () => {
      expect(findAccessTokenLink().attributes()).toMatchObject({
        href: PERSONAL_ACCESS_TOKEN_HELP_URL,
      });
    });

    it('does not have a link to personal access token docs when package is public', () => {
      createComponent({ publicPackage: true });

      expect(findAccessTokenLink().exists()).toBe(false);
    });

    it('has a link to the docs', () => {
      expect(findSetupDocsLink().attributes()).toMatchObject({
        href: PYPI_HELP_PATH,
        target: '_blank',
      });
    });
  });
});
