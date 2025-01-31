import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('MultiStepFormTemplate', () => {
  let wrapper;
  const defaultProps = {
    title: 'Form title',
    currentStep: 1,
  };

  const createComponent = (props = {}, slots) => {
    wrapper = shallowMountExtended(MultiStepFormTemplate, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      slots,
    });
  };

  const findTitle = () => wrapper.findByTestId('multi-step-form-title');
  const findContent = () => wrapper.findByTestId('multi-step-form-content');
  const findSteps = () => wrapper.findByTestId('multi-step-form-steps');
  const findActions = () => wrapper.findByTestId('multi-step-form-action');
  const findFooter = () => wrapper.findByTestId('multi-step-form-footer');

  it('renders title', () => {
    createComponent();

    expect(findTitle().text()).toBe('Form title');
  });

  describe('step display', () => {
    it('displays step X of N when stepsTotal is provided', () => {
      createComponent({ stepsTotal: 2 });

      expect(findSteps().text()).toBe('Step 1 of 2');
    });

    it('displays only step X when stepsTotal is not provided', () => {
      createComponent();

      expect(findSteps().text()).toBe('Step 1');
    });
  });

  describe('slots', () => {
    it('renders form slot content', () => {
      createComponent({}, { form: '<div class="test-form">Form Content</div>' });

      expect(findContent().exists()).toBe(true);
      expect(findContent().find('.test-form').exists()).toBe(true);
    });

    it('renders action buttons correctly when back and next slots are provided', () => {
      createComponent(
        {
          currentStep: 3,
        },
        {
          back: '<button class="back">Back</button>',
          next: '<button class="next">Next</button>',
        },
      );

      expect(findActions().find('button.back').exists()).toBe(true);
      expect(findActions().find('button.next').exists()).toBe(true);
    });

    it('does not render action buttons when no back or next slot is provided', () => {
      createComponent();

      expect(findActions().exists()).toBe(false);
    });

    it('renders footer slot content when provided', () => {
      createComponent(
        {},
        {
          footer: '<div class="test-footer">Footer Content</div>',
        },
      );

      expect(findFooter().exists()).toBe(true);
      expect(findFooter().find('.test-footer').exists()).toBe(true);
    });

    it('does not render footer section when no footer slot is provided', () => {
      createComponent();

      expect(findFooter().exists()).toBe(false);
    });
  });
});
