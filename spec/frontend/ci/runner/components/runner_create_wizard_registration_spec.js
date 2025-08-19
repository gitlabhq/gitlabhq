import Vue from 'vue';
import VueApollo from 'vue-apollo';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerCreateWizardRegistration from '~/ci/runner/components/runner_create_wizard_registration.vue';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';

Vue.use(VueApollo);

describe('Create New Runner Registration', () => {
  let wrapper;

  const defaultHandler = [
    runnerForRegistrationQuery,
    jest.fn().mockResolvedValue({
      data: {
        runner: {
          id: 1,
          description: 'test runner',
          ephemeralAuthenticationToken: 'mock-registration-token',
          creationState: 'FINISHED',
        },
      },
    }),
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RunnerCreateWizardRegistration, {
      apolloProvider: createMockApollo([defaultHandler]),
      propsData: {
        currentStep: 3,
        stepsTotal: 3,
        runnerId: 'gid://gitlab/Ci::Runner/1',
        runnersPath: '/admin/runners',
        ...props,
      },
    });

    return waitForPromises();
  };

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findToken = () => wrapper.findByTestId('token-input');
  const findCopyTokenButton = () => wrapper.findByTestId('copy-token-to-clipboard');
  const findLoadingIcon = () => wrapper.findByTestId('loading-icon-wrapper');
  const findRunnerRegisteredAlert = () => wrapper.findByTestId('runner-registered-alert');

  describe('form', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the correct props to MultiStepFormTemplate', () => {
      expect(findMultiStepFormTemplate().props()).toMatchObject({
        title: 'Register your new runner',
        currentStep: 3,
        stepsTotal: 3,
      });
    });

    it('renders runner token', async () => {
      await waitForPromises();

      expect(findToken().exists()).toBe(true);
      expect(findToken().props('value')).toBe('mock-registration-token');
    });

    it('renders copy token to clipboard button', async () => {
      await waitForPromises();

      expect(findCopyTokenButton().exists()).toBe(true);
      expect(findCopyTokenButton().props('text')).toBe('mock-registration-token');
    });
  });

  describe('on form submit', () => {
    it('displays loading state while runner registration is in progress', () => {
      createComponent();
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findRunnerRegisteredAlert().exists()).toBe(false);
    });

    it('displays success alert after runner registration completes', async () => {
      await createComponent();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findRunnerRegisteredAlert().exists()).toBe(true);
    });
  });
});
