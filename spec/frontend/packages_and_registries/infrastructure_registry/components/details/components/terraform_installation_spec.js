import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { terraformModule as packageEntity } from '../../mock_data';

Vue.use(Vuex);

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
      store,
    });
  }

  beforeEach(() => {
    createComponent();
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
