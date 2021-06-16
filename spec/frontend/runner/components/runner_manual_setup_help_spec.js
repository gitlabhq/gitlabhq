import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockRunnerInstallHelpPage = 'https://docs.gitlab.com/runner/install/';

describe('RunnerManualSetupHelp', () => {
  let wrapper;
  let originalGon;

  const findRunnerInstructions = () => wrapper.findComponent(RunnerInstructions);
  const findClipboardButtons = () => wrapper.findAllComponents(ClipboardButton);
  const findRunnerHelpTitle = () => wrapper.findByTestId('runner-help-title');
  const findCoordinatorUrl = () => wrapper.findByTestId('coordinator-url');
  const findRegistrationToken = () => wrapper.findByTestId('registration-token');
  const findRunnerHelpLink = () => wrapper.findByTestId('runner-help-link');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(RunnerManualSetupHelp, {
        provide: {
          runnerInstallHelpPage: mockRunnerInstallHelpPage,
        },
        propsData: {
          registrationToken: mockRegistrationToken,
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  beforeAll(() => {
    originalGon = global.gon;
    global.gon = { gitlab_url: TEST_HOST };
  });

  afterAll(() => {
    global.gon = originalGon;
  });

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Title contains the default runner type', () => {
    expect(findRunnerHelpTitle().text()).toMatchInterpolatedText('Set up a shared runner manually');
  });

  it('Title contains the group runner type', () => {
    createComponent({ props: { typeName: 'group' } });

    expect(findRunnerHelpTitle().text()).toMatchInterpolatedText('Set up a group runner manually');
  });

  it('Runner Install Page link', () => {
    expect(findRunnerHelpLink().attributes('href')).toBe(mockRunnerInstallHelpPage);
  });

  it('Displays the coordinator URL token', () => {
    expect(findCoordinatorUrl().text()).toBe(TEST_HOST);
    expect(findClipboardButtons().at(0).props('text')).toBe(TEST_HOST);
  });

  it('Displays the registration token', () => {
    expect(findRegistrationToken().text()).toBe(mockRegistrationToken);
    expect(findClipboardButtons().at(1).props('text')).toBe(mockRegistrationToken);
  });

  it('Displays the runner instructions', () => {
    expect(findRunnerInstructions().exists()).toBe(true);
  });
});
