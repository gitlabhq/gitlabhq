import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import {
  FORM_STEPPER_TAB_COLOR,
  FORM_STEPPER_TAB_BORDER_COLOR,
} from '~/import/offline_transfer/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('FormStepper', () => {
  let wrapper;

  const mockSteps = ['Authenticate', 'Select', 'Verify'];

  const createComponent = ({ propsData = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(FormStepper, {
      propsData: {
        completionButtonText: 'Export',
        validateStep: jest.fn().mockResolvedValue(true),
        steps: mockSteps,
        ...propsData,
      },
      slots: {
        'step-0': 'Authenticate tab content',
        'step-1': 'Select tab content',
        'step-2': 'Verify tab content',
      },
    });
  };

  const findBackButton = () => wrapper.findByTestId('back-button');
  const findContinueButton = () => wrapper.findByTestId('continue-button');
  const findCompletionButton = () => wrapper.findByTestId('completion-button');
  const findAllStepHeadings = () => wrapper.findAll('[data-testid^="step-nav"]');
  const findAllStepContents = () => wrapper.findAll('[data-testid^="step-content"]');

  const findStepHeading = (i) => wrapper.findByTestId(`step-nav-${i}`);

  const hasClasses = (element, classString) => {
    const classes = classString.split(' ');
    return classes.every((cls) => element.classes().includes(cls));
  };

  const clickContinue = async () => {
    findContinueButton().vm.$emit('click');
    await waitForPromises();
  };
  const clickBack = () => findBackButton().vm.$emit('click');
  const clickComplete = async () => {
    findCompletionButton().vm.$emit('click');
    await waitForPromises();
  };

  describe('initial render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the correct step tabs', () => {
      const stepNavs = findAllStepHeadings();

      expect(stepNavs).toHaveLength(mockSteps.length);
      mockSteps.forEach((stepText, index) => {
        expect(stepNavs.at(index).text()).toContain(stepText);
      });
    });

    it('on first tab: shows only the continue button', () => {
      expect(findBackButton().exists()).toBe(false);
      expect(findCompletionButton().exists()).toBe(false);
      expect(findContinueButton().exists()).toBe(true);
    });

    it('shows only content for the first tab', () => {
      const stepsContent = findAllStepContents();
      expect(stepsContent).toHaveLength(1);
      expect(stepsContent.at(0).text()).toContain('Authenticate tab content');
      expect(stepsContent.at(0).text()).not.toContain('Select tab content');
      expect(stepsContent.at(0).text()).not.toContain('Verify tab content');
    });

    it('shows tab headings with correct styles', () => {
      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.active)).toBe(true);
      expect(hasClasses(findStepHeading(1), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);

      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_BORDER_COLOR.active)).toBe(true);
      expect(hasClasses(findStepHeading(1), FORM_STEPPER_TAB_BORDER_COLOR.pending)).toBe(true);
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_TAB_BORDER_COLOR.pending)).toBe(true);
    });

    it('shows step numbers (not check icons) for all tabs', () => {
      mockSteps.forEach((_, i) => {
        const heading = findStepHeading(i);
        expect(heading.findComponent({ name: 'GlIcon' }).exists()).toBe(false);
        expect(heading.text()).toContain(String(i + 1));
      });
    });
  });

  describe('step navigation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('advances to the next step when continue is clicked', async () => {
      expect(findAllStepContents().at(0).text()).toContain('Authenticate tab content');
      await clickContinue();

      expect(findAllStepContents().at(0).text()).toContain('Select tab content');
    });

    it('updates tab heading styles after advancing: step 0 becomes completed, step 1 becomes active', async () => {
      await clickContinue();

      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.completed)).toBe(true);
      expect(findStepHeading(0).findComponent({ name: 'GlIcon' }).props('name')).toBe('check');
      expect(hasClasses(findStepHeading(1), FORM_STEPPER_TAB_COLOR.active)).toBe(true);
      expect(findStepHeading(1).findComponent({ name: 'GlIcon' }).exists()).toBe(false);
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);
      expect(findStepHeading(2).findComponent({ name: 'GlIcon' }).exists()).toBe(false);
    });

    it('on middle step: shows back and continue buttons, not the completion button', async () => {
      await clickContinue();

      expect(findBackButton().exists()).toBe(true);
      expect(findContinueButton().exists()).toBe(true);
      expect(findCompletionButton().exists()).toBe(false);
    });

    it('on last step: shows back and completion buttons, not the continue button', async () => {
      await clickContinue();
      await clickContinue();

      expect(findBackButton().exists()).toBe(true);
      expect(findCompletionButton().exists()).toBe(true);
      expect(findContinueButton().exists()).toBe(false);
    });

    it('backward movement correctly changes tab', async () => {
      expect(findAllStepContents().at(0).text()).toContain('Authenticate tab content');
      await clickContinue();
      await clickBack();
      await waitForPromises();

      expect(findAllStepContents().at(0).text()).toContain('Authenticate tab content');
    });

    it('backward movement correctly emits changed step', async () => {
      await clickContinue();
      await clickBack();
      expect(wrapper.emitted('stepped-back')).toHaveLength(1);
      expect(wrapper.emitted('stepped-back')[0][0]).toEqual({
        previousTabIndex: 1,
      });
    });

    it('backward movement clears completed status from the new current step and the subsequent step', async () => {
      await clickContinue();
      await clickContinue();
      await clickBack(); // return to second step
      await waitForPromises();

      // First step is before our destination so it stays completed
      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.completed)).toBe(true);

      expect(hasClasses(findStepHeading(1), FORM_STEPPER_TAB_COLOR.active)).toBe(true);
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);
    });
  });

  describe('validation', () => {
    it('calls validateStep with the current step index on continue', async () => {
      const validateStep = jest.fn().mockResolvedValue(true);
      createComponent({ propsData: { validateStep } });

      await clickContinue();

      expect(validateStep).toHaveBeenCalledWith(0);
    });

    it('does not advance and emits validation-failed when validateStep returns false', async () => {
      const validateStep = jest.fn().mockResolvedValue(false);
      createComponent({ propsData: { validateStep } });

      expect(findAllStepContents().at(0).text()).toContain('Authenticate tab content');

      await clickContinue();

      expect(findAllStepContents().at(0).text()).toContain('Authenticate tab content');
      expect(wrapper.emitted('validation-failed')).toHaveLength(1);
    });

    it('disables the continue button while validation is in progress', async () => {
      let resolveValidation;
      const validateStep = jest.fn().mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveValidation = resolve;
          }),
      );
      createComponent({ propsData: { validateStep }, mountFn: mountExtended });

      findContinueButton().trigger('click');
      await nextTick();

      expect(findContinueButton().attributes('disabled')).toBeDefined();

      resolveValidation(true);
      await waitForPromises();
      expect(findContinueButton().attributes('disabled')).toBeUndefined();
    });

    it('disables the completion button while validation is in progress on the last step', async () => {
      let resolveValidation;
      const validateStep = jest
        .fn()
        .mockResolvedValueOnce(true)
        .mockResolvedValueOnce(true)
        .mockImplementationOnce(
          () =>
            new Promise((resolve) => {
              resolveValidation = resolve;
            }),
        );
      createComponent({ propsData: { validateStep } });

      await clickContinue();
      await clickContinue();

      clickComplete();
      await waitForPromises();

      expect(findCompletionButton().attributes('disabled')).toBeDefined();

      resolveValidation(true);
      await waitForPromises();

      expect(findCompletionButton().attributes('disabled')).toBeDefined(); // disabled post-completion too
    });
  });

  describe('completion', () => {
    beforeEach(async () => {
      createComponent();
      await clickContinue();
      await clickContinue();
    });

    it('uses the completionButtonText prop for the final button label', () => {
      expect(findCompletionButton().text()).toBe('Export');
    });

    it('emits complete after the last step is submitted', async () => {
      await clickComplete();
      await nextTick();

      expect(wrapper.emitted('complete')).toHaveLength(1);
    });

    it('disables the completion button and hides the back button after form is complete', async () => {
      await clickComplete();
      await waitForPromises();

      expect(findCompletionButton().attributes('disabled')).toBeDefined();
      expect(findBackButton().exists()).toBe(false);
    });
  });
});
