import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import ConanInstallation from '~/packages_and_registries/package_registry/components/details/conan_installation.vue';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import { PACKAGE_TYPE_CONAN } from '~/packages_and_registries/package_registry/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_CONAN };

describe('ConanInstallation', () => {
  let wrapper;

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMountExtended(ConanInstallation, {
      provide: {
        conanHelpPath: 'conanHelpPath',
        conanPath: 'conanPath',
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
        packageType: 'conan',
        options: [{ value: 'conan', label: 'Show Conan commands' }],
      });
    });
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(0).props('instruction')).toBe(
        'conan install @gitlab-org/package-15 --remote=gitlab',
      );
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props('instruction')).toBe(
        'conan remote add gitlab conanPath',
      );
    });
  });
});
