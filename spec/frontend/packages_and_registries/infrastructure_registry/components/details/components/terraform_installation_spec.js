import { shallowMount } from '@vue/test-utils';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { terraformModule } from '../../mock_data';

describe('TerraformInstallation', () => {
  let wrapper;

  const defaultProvide = {
    gitlabHost: 'bar.dev',
    projectPath: 'foo',
    terraformHelpPath: '/help',
  };

  const defaultProps = {
    packageName: terraformModule.name,
    packageVersion: terraformModule.version,
  };

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);

  function createComponent() {
    wrapper = shallowMount(TerraformInstallation, {
      propsData: {
        ...defaultProps,
      },
      provide: {
        ...defaultProvide,
      },
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
