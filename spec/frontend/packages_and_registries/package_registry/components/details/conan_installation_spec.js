import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import ConanInstallation from '~/packages_and_registries/package_registry/components/details/conan_installation.vue';
import InstallationMethod from '~/packages_and_registries/package_registry/components/details/installation_method.vue';
import {
  PACKAGE_TYPE_CONAN,
  CONAN_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_CONAN };

describe('ConanInstallation', () => {
  let wrapper;

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findInstallationMethod = () => wrapper.findComponent(InstallationMethod);
  const findSetupDocsLink = () => wrapper.findComponent(GlLink);

  function createComponent() {
    wrapper = shallowMountExtended(ConanInstallation, {
      propsData: {
        packageEntity,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('install command switch', () => {
    it('does not show the installation method component', () => {
      expect(findInstallationMethod().exists()).toBe(false);
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
        `conan remote add gitlab ${packageEntity.conanUrl}`,
      );
    });

    it('has a link to the docs', () => {
      expect(findSetupDocsLink().attributes()).toMatchObject({
        href: CONAN_HELP_PATH,
        target: '_blank',
      });
    });
  });
});
