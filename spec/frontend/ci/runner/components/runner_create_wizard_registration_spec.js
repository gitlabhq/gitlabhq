import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCreateWizardRegistration from '~/ci/runner/components/runner_create_wizard_registration.vue';

describe('Create New Runner Registration', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCreateWizardRegistration, {
      propsData: {
        currentStep: 2,
        stepsTotal: 3,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);

  describe('form', () => {
    it('passes the correct props to MultiStepFormTemplate', () => {
      expect(findMultiStepFormTemplate().props()).toMatchObject({
        title: 'Register your new runner',
        currentStep: 2,
        stepsTotal: 3,
      });
    });
  });
});
