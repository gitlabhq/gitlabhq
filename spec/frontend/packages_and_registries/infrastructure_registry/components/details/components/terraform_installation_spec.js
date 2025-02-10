import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { terraformModule } from '../../mock_data';

describe('TerraformInstallation', () => {
  let wrapper;

  const defaultProvide = {
    gitlabHost: 'bar.dev',
    projectPath: 'foo',
  };

  const defaultProps = {
    packageName: terraformModule.name,
    packageVersion: terraformModule.version,
  };

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findLink = () => wrapper.findComponent(GlLink);

  function createComponent() {
    wrapper = shallowMount(TerraformInstallation, {
      propsData: {
        ...defaultProps,
      },
      provide: {
        ...defaultProvide,
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

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(0).props('instruction')).toMatchInlineSnapshot(`
"module "my_module_name" {
  source = "bar.dev/foo/Test/system-22"
  version = "0.1"
}"
`);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props('instruction')).toMatchInlineSnapshot(`
"credentials "bar.dev" {
  token = "<TOKEN>"
}"
`);
    });
  });

  describe('link to help page', () => {
    it('is rendered', () => {
      expect(findLink().attributes('href')).toBe(
        helpPagePath('user/packages/terraform_module_registry/_index', {
          anchor: 'reference-a-terraform-module',
        }),
      );
    });
  });
});
