import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import WizardOperatingSystemInstruction from '~/ci/runner/components/registration/wizard_operating_system_instruction.vue';
import PlatformsDrawer from '~/ci/runner/components/registration/platforms_drawer.vue';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import { EXECUTORS_HELP_URL, SERVICE_COMMANDS_HELP_URL } from '~/ci/runner/constants';

describe('New Runner Registration Operation Systems Instructions', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WizardOperatingSystemInstruction, {
      propsData: {
        token: 'token-123',
        title: 'Linux',
        platform: 'linux',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findPlatformsDrawer = () => wrapper.findComponent(PlatformsDrawer);
  const findStep1Section = () => wrapper.findByTestId('step-1');
  const findStep2Section = () => wrapper.findByTestId('step-2');
  const findStep3Section = () => wrapper.findByTestId('step-3');
  const findExecutorsHelpLink = () => wrapper.findByTestId('executors-help-link');
  const findServiceCommandsHelpLink = () => wrapper.findByTestId('service-commands-help-link');

  describe('platform installation drawer instructions', () => {
    it('opens and closes the drawer', async () => {
      expect(findPlatformsDrawer().props('open')).toBe(false);

      expect(wrapper.findByTestId('how-to-install-btn').exists()).toBe(true);

      await wrapper.findByTestId('how-to-install-btn').vm.$emit('click');
      expect(findPlatformsDrawer().props('open')).toBe(true);

      await findPlatformsDrawer().vm.$emit('close');
      expect(findPlatformsDrawer().props('open')).toBe(false);
    });
  });

  it('renders step 1', () => {
    expect(findStep1Section().findComponent(CliCommand).props()).toMatchObject({
      command: ['gitlab-runner register', `  --url ${TEST_HOST}`, `  --token token-123`],
      prompt: '$',
    });
  });

  it('renders step 2', () => {
    expect(findStep2Section().exists()).toBe(true);
    expect(findExecutorsHelpLink().attributes('href')).toBe(EXECUTORS_HELP_URL);
  });

  it('renders step 3', () => {
    expect(findStep3Section().findComponent(CliCommand).props()).toMatchObject({
      command: 'gitlab-runner run',
      prompt: '$',
    });
    expect(findServiceCommandsHelpLink().attributes('href')).toBe(SERVICE_COMMANDS_HELP_URL);
  });
});
