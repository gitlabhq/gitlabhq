import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import ConanInstallation from '~/packages/details/components/conan_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { conanPackage as packageEntity } from '../../mock_data';
import { registryUrl as conanPath } from '../mock_data';

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
    if (wrapper) wrapper.destroy();
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(
        findCodeInstructions()
          .at(0)
          .props('instruction'),
      ).toBe(conanInstallationCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(
        findCodeInstructions()
          .at(1)
          .props('instruction'),
      ).toBe(conanSetupCommandStr);
    });
  });
});
