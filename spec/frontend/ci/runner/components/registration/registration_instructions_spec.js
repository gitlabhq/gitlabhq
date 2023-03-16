import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { extendedWrapper, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { s__ } from '~/locale';

import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import {
  DEFAULT_PLATFORM,
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  STATUS_NEVER_CONTACTED,
  STATUS_ONLINE,
  I18N_REGISTRATION_SUCCESS,
} from '~/ci/runner/constants';
import { runnerForRegistration } from '../../mock_data';

const MOCK_TOKEN = 'MOCK_TOKEN';

const mockRunner = runnerForRegistration.data.runner;

describe('RegistrationInstructions', () => {
  let wrapper;

  const findHeading = () => wrapper.find('h1');
  const findStepAt = (i) => extendedWrapper(wrapper.findAll('section').at(i));
  const findByText = (text, container = wrapper) => container.findByText(text);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(RegistrationInstructions, {
      propsData: {
        runner: mockRunner,
        token: MOCK_TOKEN,
        platform: DEFAULT_PLATFORM,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    window.gon.gitlab_url = TEST_HOST;
  });

  describe('renders heading', () => {
    it('when runner is loaded, shows heading', () => {
      createComponent();
      expect(findHeading().text()).toContain(mockRunner.description);
    });

    it('when runner is loaded, shows heading safely', () => {
      const description = '<script>hacked();</script>';

      createComponent({
        runner: {
          ...mockRunner,
          description,
        },
      });

      expect(findHeading().text()).toBe('Register "<script>hacked();</script>" runner');
      expect(findHeading().element.innerHTML).toBe(
        'Register "&lt;script&gt;hacked();&lt;/script&gt;" runner',
      );
    });

    it('when runner is loading, shows default heading', () => {
      createComponent({
        loading: true,
        runner: null,
      });

      expect(findHeading().text()).toBe(s__('Runners|Register runner'));
    });
  });

  it('renders legacy instructions', () => {
    createComponent();
    findByText('How do I install GitLab Runner?').vm.$emit('click');

    expect(wrapper.emitted('toggleDrawer')).toHaveLength(1);
  });

  it('renders step 1', () => {
    createComponent();
    const step1 = findStepAt(0);

    expect(step1.findComponent(CliCommand).props()).toEqual({
      command: [
        'gitlab-runner register',
        `  --url ${TEST_HOST}`,
        `  --registration-token ${MOCK_TOKEN}`,
        `  --description '${mockRunner.description}'`,
      ],
      prompt: '$',
    });
    expect(step1.find('[data-testid="runner-token"]').text()).toBe(MOCK_TOKEN);
    expect(step1.findComponent(ClipboardButton).props('text')).toBe(MOCK_TOKEN);
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

  it('render step 1 after token is not visible', () => {
    createComponent({
      token: undefined,
    });

    const step1 = findStepAt(0);

    expect(step1.findComponent(CliCommand).props()).toEqual({
      command: [
        'gitlab-runner register',
        `  --url ${TEST_HOST}`,
        `  --description '${mockRunner.description}'`,
      ],
      prompt: '$',
    });
    expect(step1.find('[data-testid="runner-token"]').exists()).toBe(false);
    expect(step1.findComponent(ClipboardButton).exists()).toBe(false);
  });

  it('renders step 2', () => {
    createComponent();
    const step2 = findStepAt(1);

    expect(findByText('Not sure which one to select?', step2).attributes('href')).toBe(
      EXECUTORS_HELP_URL,
    );
  });

  it('renders step 3', () => {
    createComponent();
    const step3 = findStepAt(2);

    expect(step3.findComponent(CliCommand).props()).toEqual({
      command: 'gitlab-runner run',
      prompt: '$',
    });

    expect(findByText('system or user service', step3).attributes('href')).toBe(
      SERVICE_COMMANDS_HELP_URL,
    );
  });

  describe('success state', () => {
    describe('when the runner has not been registered', () => {
      beforeEach(() => {
        createComponent({
          runner: {
            ...mockRunner,
            status: STATUS_NEVER_CONTACTED,
          },
        });
      });

      it('does not show success message', () => {
        expect(wrapper.text()).not.toContain(I18N_REGISTRATION_SUCCESS);
      });
    });

    describe('when the runner has been registered', () => {
      beforeEach(() => {
        createComponent({
          runner: {
            ...mockRunner,
            status: STATUS_ONLINE,
          },
        });
      });

      it('shows success message', () => {
        expect(wrapper.text()).toContain('🎉');
        expect(wrapper.text()).toContain(I18N_REGISTRATION_SUCCESS);
      });
    });
  });
});
