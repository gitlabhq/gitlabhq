import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { extendedWrapper, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';

import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import {
  DEFAULT_PLATFORM,
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
} from '~/ci/runner/constants';

const REGISTRATION_TOKEN = 'REGISTRATION_TOKEN';
const DUMMY_GON = {
  gitlab_url: TEST_HOST,
};

describe('RegistrationInstructions', () => {
  let wrapper;
  let originalGon;

  const findStepAt = (i) => extendedWrapper(wrapper.findAll('section').at(i));
  const findByText = (text, container = wrapper) => container.findByText(text);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(RegistrationInstructions, {
      propsData: {
        platform: DEFAULT_PLATFORM,
        token: REGISTRATION_TOKEN,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeAll(() => {
    originalGon = window.gon;
    window.gon = { ...DUMMY_GON };
  });

  afterAll(() => {
    window.gon = originalGon;
  });

  beforeEach(() => {
    createComponent();
  });

  it('renders legacy instructions', () => {
    findByText('How do I install GitLab Runner?').vm.$emit('click');

    expect(wrapper.emitted('toggleDrawer')).toHaveLength(1);
  });

  it('renders step 1', () => {
    const step1 = findStepAt(0);

    expect(step1.findComponent(CliCommand).props()).toEqual({
      command: [
        'gitlab-runner register',
        `  --url ${TEST_HOST}`,
        `  --registration-token ${REGISTRATION_TOKEN}`,
      ],
      prompt: '$',
    });
    expect(step1.find('code').text()).toBe(REGISTRATION_TOKEN);
    expect(step1.findComponent(ClipboardButton).props('text')).toBe(REGISTRATION_TOKEN);
  });

  it('renders step 1 in loading state', () => {
    createComponent({
      loading: true,
    });

    const step1 = findStepAt(0);

    expect(step1.findComponent(GlSkeletonLoader).exists()).toBe(true);
    expect(step1.find('code').exists()).toBe(false);
    expect(step1.findComponent(ClipboardButton).exists()).toBe(false);
  });

  it('renders step 2', () => {
    const step2 = findStepAt(1);

    expect(findByText('Not sure which one to select?', step2).attributes('href')).toBe(
      EXECUTORS_HELP_URL,
    );
  });

  it('renders step 3', () => {
    const step3 = findStepAt(2);

    expect(step3.findComponent(CliCommand).props()).toEqual({
      command: 'gitlab-runner run',
      prompt: '$',
    });

    expect(findByText('system or user service', step3).attributes('href')).toBe(
      SERVICE_COMMANDS_HELP_URL,
    );
  });
});
