import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';

import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';

import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import {
  DEFAULT_PLATFORM,
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  STATUS_NEVER_CONTACTED,
  STATUS_ONLINE,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
  I18N_REGISTRATION_SUCCESS,
} from '~/ci/runner/constants';
import { runnerForRegistration, mockAuthenticationToken } from '../../mock_data';

Vue.use(VueApollo);

const mockRunner = {
  ...runnerForRegistration.data.runner,
  ephemeralAuthenticationToken: mockAuthenticationToken,
};
const mockRunnerWithoutToken = {
  ...runnerForRegistration.data.runner,
  ephemeralAuthenticationToken: null,
};

const mockRunnerId = `${getIdFromGraphQLId(mockRunner.id)}`;

describe('RegistrationInstructions', () => {
  let wrapper;
  let mockRunnerQuery;

  const findHeading = () => wrapper.find('h1');
  const findStepAt = (i) => extendedWrapper(wrapper.findAll('section').at(i));
  const findByText = (text, container = wrapper) => container.findByText(text);

  const waitForPolling = async () => {
    jest.advanceTimersByTime(RUNNER_REGISTRATION_POLLING_INTERVAL_MS);
    await waitForPromises();
  };

  const mockBeforeunload = () => {
    const event = new Event('beforeunload');
    const preventDefault = jest.spyOn(event, 'preventDefault');
    const returnValueSetter = jest.spyOn(event, 'returnValue', 'set');

    return {
      event,
      preventDefault,
      returnValueSetter,
    };
  };

  const mockResolvedRunner = (runner = mockRunner) => {
    mockRunnerQuery.mockResolvedValue({
      data: {
        runner,
      },
    });
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(RegistrationInstructions, {
      apolloProvider: createMockApollo([[runnerForRegistrationQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        platform: DEFAULT_PLATFORM,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    mockRunnerQuery = jest.fn();
    mockResolvedRunner();
  });

  beforeEach(() => {
    window.gon.gitlab_url = TEST_HOST;
  });

  it('loads runner with id', () => {
    createComponent();

    expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunner.id });
  });

  describe('heading', () => {
    it('when runner is loaded, shows heading', async () => {
      createComponent();
      await waitForPromises();

      expect(findHeading().text()).toContain(mockRunner.description);
    });

    it('when runner is loaded, shows heading safely', async () => {
      mockResolvedRunner({
        ...mockRunner,
        description: '<script>hacked();</script>',
      });

      createComponent();
      await waitForPromises();

      expect(findHeading().text()).toBe('Register "<script>hacked();</script>" runner');
      expect(findHeading().element.innerHTML).toBe(
        'Register "&lt;script&gt;hacked();&lt;/script&gt;" runner',
      );
    });

    it('when runner is loading, shows default heading', () => {
      createComponent();

      expect(findHeading().text()).toBe(s__('Runners|Register runner'));
    });
  });

  it('renders legacy instructions', () => {
    createComponent();

    findByText('How do I install GitLab Runner?').vm.$emit('click');

    expect(wrapper.emitted('toggleDrawer')).toHaveLength(1);
  });

  describe('step 1', () => {
    it('renders step 1', async () => {
      createComponent();
      await waitForPromises();

      const step1 = findStepAt(0);

      expect(step1.findComponent(CliCommand).props()).toEqual({
        command: [
          'gitlab-runner register',
          `  --url ${TEST_HOST}`,
          `  --token ${mockAuthenticationToken}`,
        ],
        prompt: '$',
      });
      expect(step1.findByTestId('runner-token').text()).toBe(mockAuthenticationToken);
      expect(step1.findComponent(ClipboardButton).props('text')).toBe(mockAuthenticationToken);
    });

    it('renders step 1 in loading state', () => {
      createComponent();

      const step1 = findStepAt(0);

      expect(step1.findComponent(GlSkeletonLoader).exists()).toBe(true);
      expect(step1.find('code').exists()).toBe(false);
      expect(step1.findComponent(ClipboardButton).exists()).toBe(false);
    });

    it('render step 1 after token is not visible', async () => {
      mockResolvedRunner(mockRunnerWithoutToken);

      createComponent();
      await waitForPromises();

      const step1 = findStepAt(0);

      expect(step1.findComponent(CliCommand).props('command')).toEqual([
        'gitlab-runner register',
        `  --url ${TEST_HOST}`,
      ]);
      expect(step1.findByTestId('runner-token').exists()).toBe(false);
      expect(step1.findComponent(ClipboardButton).exists()).toBe(false);
    });

    describe('polling for changes', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('fetches data', () => {
        expect(mockRunnerQuery).toHaveBeenCalledTimes(1);
      });

      it('polls', async () => {
        await waitForPolling();
        expect(mockRunnerQuery).toHaveBeenCalledTimes(2);

        await waitForPolling();
        expect(mockRunnerQuery).toHaveBeenCalledTimes(3);
      });

      it('when runner is online, stops polling', async () => {
        mockResolvedRunner({ ...mockRunner, status: STATUS_ONLINE });
        await waitForPolling();

        expect(mockRunnerQuery).toHaveBeenCalledTimes(2);
        await waitForPolling();

        expect(mockRunnerQuery).toHaveBeenCalledTimes(2);
      });

      it('when token is no longer visible in the API, it is still visible in the UI', async () => {
        mockResolvedRunner(mockRunnerWithoutToken);
        await waitForPolling();

        const step1 = findStepAt(0);
        expect(step1.findComponent(CliCommand).props('command')).toEqual([
          'gitlab-runner register',
          `  --url ${TEST_HOST}`,
          `  --token ${mockAuthenticationToken}`,
        ]);
        expect(step1.findByTestId('runner-token').text()).toBe(mockAuthenticationToken);
        expect(step1.findComponent(ClipboardButton).props('text')).toBe(mockAuthenticationToken);
      });

      it('when runner is not available (e.g. deleted), the UI does not update', async () => {
        mockResolvedRunner(null);
        await waitForPolling();

        const step1 = findStepAt(0);
        expect(step1.findComponent(CliCommand).props('command')).toEqual([
          'gitlab-runner register',
          `  --url ${TEST_HOST}`,
          `  --token ${mockAuthenticationToken}`,
        ]);
        expect(step1.findByTestId('runner-token').text()).toBe(mockAuthenticationToken);
        expect(step1.findComponent(ClipboardButton).props('text')).toBe(mockAuthenticationToken);
      });
    });
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
      beforeEach(async () => {
        createComponent();

        await waitForPolling();

        mockResolvedRunner({ ...mockRunner, status: STATUS_NEVER_CONTACTED });

        await waitForPolling();
      });

      it('does not show success message', () => {
        expect(wrapper.text()).not.toContain(I18N_REGISTRATION_SUCCESS);
      });

      describe('when the page is closing', () => {
        it('warns the user against closing', () => {
          const { event, preventDefault, returnValueSetter } = mockBeforeunload();

          expect(preventDefault).not.toHaveBeenCalled();
          expect(returnValueSetter).not.toHaveBeenCalled();

          window.dispatchEvent(event);

          expect(preventDefault).toHaveBeenCalledWith();
          expect(returnValueSetter).toHaveBeenCalledWith(expect.any(String));
        });
      });
    });

    describe('when the runner has been registered', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPolling();

        mockResolvedRunner({ ...mockRunner, status: STATUS_ONLINE });
        await waitForPolling();
      });

      it('shows success message', () => {
        expect(wrapper.text()).toContain('🎉');
        expect(wrapper.text()).toContain(I18N_REGISTRATION_SUCCESS);
      });

      describe('when the page is closing', () => {
        it('does not warn the user against closing', () => {
          const { event, preventDefault, returnValueSetter } = mockBeforeunload();

          expect(preventDefault).not.toHaveBeenCalled();
          expect(returnValueSetter).not.toHaveBeenCalled();

          window.dispatchEvent(event);

          expect(preventDefault).not.toHaveBeenCalled();
          expect(returnValueSetter).not.toHaveBeenCalled();
        });
      });
    });
  });
});
