import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCreateWizardOptionalFields from '~/ci/runner/components/runner_create_wizard_optional_fields.vue';

describe('Create Runner Optional Fields', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCreateWizardOptionalFields, {
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
  const findNextButton = () => wrapper.findByTestId('next-button');
  const findBackButton = () => wrapper.findByTestId('back-button');

  describe('form', () => {
    it('passes the correct props to MultiStepFormTemplate', () => {
      expect(findMultiStepFormTemplate().props()).toMatchObject({
        title: 'Optional configuration details',
        currentStep: 2,
        stepsTotal: 3,
      });
    });
  });

  it('renders the Next step button', () => {
    expect(findNextButton().text()).toBe('Next step');
    expect(findNextButton().props('disabled')).toBe(true);
  });

  describe('back button', () => {
    it('renders the Go back button', () => {
      expect(findBackButton().text()).toBe('Go back');
    });

    it(`emits the "back" event when the back button is clicked`, () => {
      findBackButton().vm.$emit('click');
      expect(wrapper.emitted('back')).toHaveLength(1);
    });
  });
});
