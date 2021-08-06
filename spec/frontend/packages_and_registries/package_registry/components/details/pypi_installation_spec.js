import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import PypiInstallation from '~/packages_and_registries/package_registry/components/details/pypi_installation.vue';
import {
  PACKAGE_TYPE_PYPI,
  TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
} from '~/packages_and_registries/package_registry/constants';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_PYPI };

describe('PypiInstallation', () => {
  let wrapper;

  const pipCommandStr = 'pip install @gitlab-org/package-15 --extra-index-url pypiPath';
  const pypiSetupStr = `[gitlab]
repository = pypiSetupPath
username = __token__
password = <your personal access token>`;

  const pipCommand = () => wrapper.findByTestId('pip-command');
  const setupInstruction = () => wrapper.findByTestId('pypi-setup-content');

  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMountExtended(PypiInstallation, {
      provide: {
        pypiHelpPath: 'pypiHelpPath',
        pypiPath: 'pypiPath',
        pypiSetupPath: 'pypiSetupPath',
      },
      propsData: {
        packageEntity,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('install command switch', () => {
    it('has the installation title component', () => {
      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: 'pypi',
        options: [{ value: 'pypi', label: 'Show PyPi commands' }],
      });
    });
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
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
  });
});
