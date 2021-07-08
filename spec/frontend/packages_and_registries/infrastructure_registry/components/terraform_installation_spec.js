import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { terraformModule as packageEntity } from 'jest/packages/mock_data';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/components/terraform_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('TerraformInstallation', () => {
  let wrapper;

  const store = new Vuex.Store({
    state: {
      packageEntity,
      gitlabHost: 'bar.dev',
      projectPath: 'foo',
    },
  });

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);

  function createComponent() {
    wrapper = shallowMount(TerraformInstallation, {
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

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(0).props('instruction')).toMatchInlineSnapshot(`
        "module \\"my_module_name\\" {
          source = \\"bar.dev/foo/Test/system-22\\"
          version = \\"0.1\\"
        }"
      `);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props('instruction')).toMatchInlineSnapshot(`
        "credentials \\"bar.dev\\" {
          token = \\"<TOKEN>\\"
        }"
      `);
    });
  });
});
