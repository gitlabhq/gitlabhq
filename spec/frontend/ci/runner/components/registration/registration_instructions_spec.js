import { GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';

import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import { DEFAULT_PLATFORM, INSTALL_HELP_URL, EXECUTORS_HELP_URL } from '~/ci/runner/constants';

const REGISTRATION_TOKEN = 'REGISTRATION_TOKEN';
const DUMMY_GON = {
  gitlab_url: TEST_HOST,
};

describe('RegistrationInstructions', () => {
  let wrapper;
  let originalGon;

  const findStepAt = (i) => wrapper.findAll('section').at(i);
  const findLink = (href, container = wrapper) =>
    container.findAllComponents(GlLink).filter((w) => w.attributes('href') === href);

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
    expect(findLink(INSTALL_HELP_URL).exists()).toBe(true);
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

    expect(findLink(EXECUTORS_HELP_URL, step2).exists()).toBe(true);
  });

  it('renders step 3', () => {
    const step3 = findStepAt(2);

    expect(step3.findComponent(CliCommand).props()).toEqual({
      command: 'gitlab-runner run',
      prompt: '$',
    });
  });
});
