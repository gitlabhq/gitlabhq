import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import NugetInstallation from '~/packages_and_registries/package_registry/components/details/nuget_installation.vue';
import {
  TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND,
  PACKAGE_TYPE_NUGET,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_NUGET };

describe('NugetInstallation', () => {
  let wrapper;

  const nugetInstallationCommandStr = 'nuget install @gitlab-org/package-15 -Source "GitLab"';
  const nugetSetupCommandStr =
    'nuget source Add -Name "GitLab" -Source "nugetPath" -UserName <your_username> -Password <your_token>';

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMountExtended(NugetInstallation, {
      provide: {
        nugetHelpPath: 'nugetHelpPath',
        nugetPath: 'nugetPath',
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

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('install command switch', () => {
    it('has the installation title component', () => {
      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: 'nuget',
        options: [{ value: 'nuget', label: 'Show Nuget commands' }],
      });
    });
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(0).props()).toMatchObject({
        instruction: nugetInstallationCommandStr,
        trackingAction: TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: nugetSetupCommandStr,
        trackingAction: TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND,
      });
    });
  });
});
