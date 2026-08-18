import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import {
  FORM_STEPPER_TAB_COLOR,
  FORM_STEPPER_ACTIVE_TAB_BORDER,
} from '~/import/offline_transfer/constants';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/scroll_utils');

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

  const findBackButton = () => wrapper.findComponentByTestId('back-button');
  const findContinueButton = () => wrapper.findComponentByTestId('continue-button');
  const findCompletionButton = () => wrapper.findComponentByTestId('completion-button');
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

    it('shows tab headings with correct styles and attributes', () => {
      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.active)).toBe(true);
      expect(findStepHeading(0).attributes('aria-current')).toBe('step');
      expect(hasClasses(findStepHeading(1), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);
      expect(findStepHeading(1).attributes('aria-current')).toBeUndefined();
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_TAB_COLOR.pending)).toBe(true);
      expect(findStepHeading(2).attributes('aria-current')).toBeUndefined();

      expect(hasClasses(findStepHeading(0), FORM_STEPPER_ACTIVE_TAB_BORDER)).toBe(true);
      expect(hasClasses(findStepHeading(1), FORM_STEPPER_ACTIVE_TAB_BORDER)).toBe(false);
      expect(hasClasses(findStepHeading(2), FORM_STEPPER_ACTIVE_TAB_BORDER)).toBe(false);
    });

    it('shows step numbers (not check icons) for all tabs', () => {
      mockSteps.forEach((_, i) => {
        const heading = findStepHeading(i);
        expect(heading.findComponent({ name: 'GlIcon' }).exists()).toBe(false);
        expect(heading.text()).toContain(String(i + 1));
      });
    });
  });

  describe('canStart check', () => {
    it('hides the continue button on first step when canStart is false', () => {
      createComponent({ propsData: { canStart: false } });
      expect(findContinueButton().exists()).toBe(false);
    });

    it('shows the continue button on first step when canStart is true', () => {
      createComponent({ propsData: { canStart: true } });

      expect(findContinueButton().exists()).toBe(true);
    });

    it('only gates the first step', async () => {
      createComponent();
      await clickContinue();
      expect(findContinueButton().exists()).toBe(true);

      await wrapper.setProps({ canStart: false });

      expect(findContinueButton().exists()).toBe(true);
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

    it('forward movement emits "stepped-forward" event with the passed step index', async () => {
      await clickContinue();

      expect(wrapper.emitted('stepped-forward')).toHaveLength(1);
      expect(wrapper.emitted('stepped-forward')[0][0]).toEqual({
        previousTabIndex: 0,
      });
    });

    it('updates tab heading styles after advancing: step 0 becomes completed, step 1 becomes active', async () => {
      await clickContinue();

      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.completed)).toBe(true);
      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.active)).toBe(false);
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
      expect(findCompletionButton().text()).toBe('Export');
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
      expect(hasClasses(findStepHeading(0), FORM_STEPPER_TAB_COLOR.active)).toBe(false);

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
      expect(scrollToElement).toHaveBeenCalled();
    });

    it('does not scroll when validation passes and the step advances', async () => {
      const validateStep = jest.fn().mockResolvedValue(true);
      createComponent({ propsData: { validateStep } });

      await clickContinue();

      expect(scrollToElement).not.toHaveBeenCalled();
    });

    it('on final step, scrolls to the final step content when completion validation fails', async () => {
      const validateStep = jest
        .fn()
        .mockResolvedValueOnce(true)
        .mockResolvedValueOnce(true)
        .mockResolvedValueOnce(false);
      createComponent({ propsData: { validateStep } });

      await clickContinue();
      await clickContinue();
      await clickComplete();

      expect(wrapper.emitted('validation-failed')).toHaveLength(1);
      expect(scrollToElement).toHaveBeenCalledWith(wrapper.findByTestId('step-content-2').element);
    });

    it('does not emit "stepped-forward" when validation fails', async () => {
      const validateStep = jest.fn().mockResolvedValue(false);
      createComponent({ propsData: { validateStep } });

      await clickContinue();

      expect(wrapper.emitted('stepped-forward')).toBeUndefined();
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

      expect(findContinueButton().attributes('aria-disabled')).toBe('true');

      resolveValidation(true);
      await waitForPromises();
      expect(findContinueButton().attributes('aria-disabled')).toBeUndefined();
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

      expect(findCompletionButton().attributes('disabled')).toBeUndefined();
    });
  });

  describe('final step', () => {
    const createComponentOnLastStep = async (propsData = {}) => {
      createComponent({ propsData });
      await clickContinue();
      await clickContinue();
    };

    it('when Complete button is clicked emits `complete`', async () => {
      await createComponentOnLastStep();
      await clickComplete();
      await nextTick();

      expect(wrapper.emitted('complete')).toHaveLength(1);
    });

    describe('when the parent passes isSubmitting as true', () => {
      beforeEach(async () => {
        await createComponentOnLastStep({ isSubmitting: true });
      });

      it('puts Complete button in a loading state', () => {
        expect(findCompletionButton().props('loading')).toBe(true);
      });

      it('hides the back button', () => {
        expect(findBackButton().exists()).toBe(false);
      });
    });

    describe('when the parent passes isCompletionDisabled as true', () => {
      beforeEach(async () => {
        await createComponentOnLastStep({ isCompletionDisabled: true });
      });

      it('disables the completion button', () => {
        expect(findCompletionButton().attributes('disabled')).toBeDefined();
      });

      it('keeps the back button visible so the user can go back and edit', () => {
        expect(findBackButton().exists()).toBe(true);
      });
    });

    describe('when the parent reports submission succeeded', () => {
      beforeEach(async () => {
        await createComponentOnLastStep({ isFormComplete: true });
      });

      it('hides the completion button', () => {
        expect(findCompletionButton().exists()).toBe(false);
      });

      it('hides the back button', () => {
        expect(findBackButton().exists()).toBe(false);
      });

      it('marks every step heading as completed with a check icon', () => {
        mockSteps.forEach((_, i) => {
          const heading = findStepHeading(i);

          expect(hasClasses(heading, FORM_STEPPER_TAB_COLOR.completed)).toBe(true);
          expect(heading.findComponent({ name: 'GlIcon' }).props('name')).toBe('check');
        });
      });
    });
  });
});
