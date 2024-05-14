import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import GoogleCloudRegistrationInstructionsModal from '~/ci/runner/components/registration/google_cloud_registration_instructions_modal.vue';

const mockSetupBashScript = 'mockSetupBashScript';
const mockSetupTerraformFile = 'mockSetupTerraformFile';
const mockApplyTerraformScript = 'mockApplyTerraformScript';

describe('Modal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findCliCommands = () => wrapper.findAllComponents(CliCommand);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(GoogleCloudRegistrationInstructionsModal, {
      propsData: {
        setupBashScript: mockSetupBashScript,
        setupTerraformFile: mockSetupTerraformFile,
        applyTerraformScript: mockApplyTerraformScript,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('shows modal', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      actionCancel: { text: 'Close' },
      modalId: 'setup-instructions',
      size: 'md',
      title: 'Setup instructions',
    });
  });

  it('shows commands text', () => {
    createComponent();

    const commands = findCliCommands();

    expect(commands).toHaveLength(3);

    expect(commands.at(0).props('command')).toBe(mockSetupBashScript);
    expect(commands.at(0).props('buttonTitle')).toBe('Copy commands');

    expect(commands.at(1).props('command')).toBe(mockSetupTerraformFile);
    expect(commands.at(1).props('buttonTitle')).toBe('Copy Terraform configuration');

    expect(commands.at(2).props('command')).toBe(mockApplyTerraformScript);
    expect(commands.at(2).props('buttonTitle')).toBe('Copy commands');
  });

  it('emits change event when modal visibility changes', async () => {
    createComponent();

    await findModal().vm.$emit('change', true);
    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  it('passes visible prop to gl-modal', () => {
    createComponent({
      props: {
        visible: true,
      },
    });

    expect(findModal().props('visible')).toBe(true);
  });
});
