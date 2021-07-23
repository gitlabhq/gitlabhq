import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { registryUrl as conanPath } from 'jest/packages/details/mock_data';
import { conanPackage as packageEntity } from 'jest/packages/mock_data';
import ConanInstallation from '~/packages_and_registries/package_registry/components/details/conan_installation.vue';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ConanInstallation', () => {
  let wrapper;

  const conanInstallationCommandStr = 'foo/command';
  const conanSetupCommandStr = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      conanPath,
    },
    getters: {
      conanInstallationCommand: () => conanInstallationCommandStr,
      conanSetupCommand: () => conanSetupCommandStr,
    },
  });

  const findCodeInstructions = () => wrapper.findAll(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMount(ConanInstallation, {
      localVue,
      store,
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
      expect(findCodeInstructions().at(0).props('instruction')).toBe(conanInstallationCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props('instruction')).toBe(conanSetupCommandStr);
    });
  });
});
