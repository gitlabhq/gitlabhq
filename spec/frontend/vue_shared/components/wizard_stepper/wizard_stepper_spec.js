import { mount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import WizardStepper from '~/vue_shared/components/wizard_stepper/wizard_stepper.vue';

describe('WizardStepper', () => {
  let wrapper;

  const baseSteps = [
    { id: 1, label: 'Details' },
    { id: 2, label: 'Requirements' },
    { id: 3, label: 'Projects' },
    { id: 4, label: 'Review' },
  ];

  const createComponent = ({ steps = baseSteps, currentStep = 1, listeners = {} } = {}) => {
    wrapper = mount(WizardStepper, {
      propsData: { steps, currentStep },
      listeners,
    });
  };

  const findStepRoot = (id) => wrapper.find(`[data-testid="step-${id}"]`);
  const findStepLabel = (id) => findStepRoot(id).find('[data-testid="step-label"]');
  const findStepIndicator = (id) => findStepRoot(id).find('[data-testid="step-indicator"]');
  const findStepDoneIcon = (id) => findStepRoot(id).find('[data-testid="step-icon-done"]');
  const findStepErrorIcon = (id) => findStepRoot(id).find('[data-testid="step-icon-error"]');
  const findStepErrorMessage = (id) => findStepRoot(id).find('[data-testid="step-error-message"]');

  describe('basic rendering', () => {
    beforeEach(() => createComponent());

    it('renders all step labels', () => {
      baseSteps.forEach(({ label }) => {
        expect(wrapper.text()).toContain(label);
      });
    });

    it('renders connectors between steps but not after the last one', () => {
      const connectors = wrapper.findAll('[aria-hidden="true"]');
      expect(connectors).toHaveLength(baseSteps.length - 1);
    });
  });

  describe('current state', () => {
    beforeEach(() => createComponent({ currentStep: 2 }));

    it('renders the current step indicator with blue background', () => {
      const indicator = findStepIndicator(2);
      expect(indicator.exists()).toBe(true);
      expect(indicator.classes()).toEqual(
        expect.arrayContaining(['gl-bg-status-info', 'gl-text-status-info']),
      );
      expect(indicator.text()).toBe('2');
    });

    it('renders the current step label as bold', () => {
      expect(findStepLabel(2).classes()).toContain('gl-font-bold');
    });
  });

  describe('done state', () => {
    beforeEach(() => createComponent({ currentStep: 3 }));

    it('renders a green check icon for completed steps', () => {
      const icon = findStepDoneIcon(1).findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('check-circle-filled');
      expect(icon.classes()).toContain('gl-text-status-success');
    });

    it('does not render a number indicator for done steps', () => {
      expect(findStepIndicator(1).exists()).toBe(false);
    });

    it('renders done step labels muted (not bold)', () => {
      expect(findStepLabel(1).classes()).toContain('gl-text-subtle');
      expect(findStepLabel(1).classes()).not.toContain('gl-font-bold');
    });
  });

  describe('pending state', () => {
    beforeEach(() => createComponent({ currentStep: 1 }));

    it('renders a muted indicator for future steps', () => {
      const indicator = findStepIndicator(3);
      expect(indicator.classes()).toEqual(
        expect.arrayContaining(['gl-bg-strong', 'gl-text-subtle']),
      );
      expect(indicator.text()).toBe('3');
    });

    it('renders pending step labels muted', () => {
      expect(findStepLabel(3).classes()).toContain('gl-text-subtle');
    });
  });

  describe('disabled state', () => {
    const disabledSteps = [
      { id: 1, label: 'Details' },
      { id: 2, label: 'Requirements', disabled: true },
      { id: 3, label: 'Projects' },
    ];

    it('sets aria-disabled="true" on a disabled step', () => {
      createComponent({ steps: disabledSteps, currentStep: 1 });
      expect(findStepRoot(2).attributes('aria-disabled')).toBe('true');
    });

    it('does not set aria-disabled on non-disabled steps', () => {
      createComponent({ steps: disabledSteps, currentStep: 1 });
      expect(findStepRoot(1).attributes('aria-disabled')).toBeUndefined();
      expect(findStepRoot(3).attributes('aria-disabled')).toBeUndefined();
    });

    it('renders disabled step as <button disabled> when interactive', () => {
      createComponent({
        steps: disabledSteps,
        currentStep: 1,
        listeners: { 'step-click': () => {} },
      });
      const root = findStepRoot(2);
      expect(root.element.tagName).toBe('BUTTON');
      expect(root.element.disabled).toBe(true);
    });

    it('renders the muted indicator (not the done check) for a disabled step whose id is below currentStep', () => {
      // Regression: disabled state must take precedence over the "done" state so
      // a placeholder/disabled step never appears as completed when later steps
      // become active.
      createComponent({ steps: disabledSteps, currentStep: 3 });
      expect(findStepDoneIcon(2).exists()).toBe(false);
      expect(findStepIndicator(2).exists()).toBe(true);
      expect(findStepIndicator(2).text()).toBe('2');
    });

    it('keeps disabled-step buttons free of the default browser button background', () => {
      createComponent({
        steps: disabledSteps,
        currentStep: 1,
        listeners: { 'step-click': () => {} },
      });
      const classes = findStepRoot(2).classes();
      expect(classes).toContain('gl-border-0');
      expect(classes).toContain('gl-bg-transparent');
      expect(classes).toContain('gl-p-0');
    });
  });

  describe('error state', () => {
    const errorSteps = [
      { id: 1, label: 'Details', error: true, errorMessage: 'Name is required' },
      { id: 2, label: 'Requirements' },
    ];

    beforeEach(() => createComponent({ steps: errorSteps, currentStep: 2 }));

    it('renders an error icon for the error step', () => {
      const icon = findStepErrorIcon(1).findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('error');
      expect(icon.classes()).toContain('gl-text-status-danger');
    });

    it('does not render the done icon or number indicator for the error step', () => {
      expect(findStepDoneIcon(1).exists()).toBe(false);
      expect(findStepIndicator(1).exists()).toBe(false);
    });

    it('renders the error step label in red', () => {
      expect(findStepLabel(1).classes()).toContain('gl-text-status-danger');
    });

    it('sets aria-invalid="true" on the error step', () => {
      expect(findStepRoot(1).attributes('aria-invalid')).toBe('true');
    });

    it('sets aria-describedby referencing an sr-only error description element', () => {
      const errorMessageId = findStepRoot(1).attributes('aria-describedby');
      expect(errorMessageId).toMatch(/^wizard-stepper-\d+-error-1$/);

      const errorEl = findStepErrorMessage(1);
      expect(errorEl.exists()).toBe(true);
      expect(errorEl.attributes('id')).toBe(errorMessageId);
      expect(errorEl.classes()).toContain('gl-sr-only');
      expect(errorEl.text()).toBe('Name is required');
    });

    it('generates unique error message ids across multiple instances', () => {
      const stepsA = [{ id: 1, label: 'A', error: true }];
      const stepsB = [{ id: 1, label: 'B', error: true }];
      const wrapperA = mount(WizardStepper, { propsData: { steps: stepsA, currentStep: 1 } });
      const wrapperB = mount(WizardStepper, { propsData: { steps: stepsB, currentStep: 1 } });

      const idA = wrapperA.find('[data-testid="step-1"]').attributes('aria-describedby');
      const idB = wrapperB.find('[data-testid="step-1"]').attributes('aria-describedby');

      expect(idA).not.toBe(idB);
    });

    it('falls back to a default error message when errorMessage is not provided', () => {
      createComponent({
        steps: [{ id: 1, label: 'Details', error: true }],
        currentStep: 1,
      });
      expect(findStepErrorMessage(1).text()).toBe('Step has validation errors');
    });
  });

  describe('step-click emit', () => {
    it('emits step-click with the step id when a non-disabled step is clicked', async () => {
      createComponent({ listeners: { 'step-click': () => {} } });
      await findStepRoot(2).trigger('click');
      expect(wrapper.emitted('step-click')).toEqual([[2]]);
    });

    it('does not emit step-click when a disabled step is clicked', async () => {
      const steps = [
        { id: 1, label: 'Details' },
        { id: 2, label: 'Requirements', disabled: true },
      ];
      createComponent({ steps, currentStep: 1, listeners: { 'step-click': () => {} } });
      await findStepRoot(2).trigger('click');
      expect(wrapper.emitted('step-click')).toBeUndefined();
    });

    it('emits step-click for done, current, and pending steps when interactive', async () => {
      createComponent({ currentStep: 2, listeners: { 'step-click': () => {} } });
      await findStepRoot(1).trigger('click'); // done
      await findStepRoot(2).trigger('click'); // current
      await findStepRoot(3).trigger('click'); // pending
      expect(wrapper.emitted('step-click')).toEqual([[1], [2], [3]]);
    });
  });

  describe('keyboard / a11y contract', () => {
    it('renders interactive steps as <button> for native Enter/Space activation', () => {
      createComponent({ listeners: { 'step-click': () => {} } });
      baseSteps.forEach((step) => {
        expect(findStepRoot(step.id).element.tagName).toBe('BUTTON');
      });
    });

    it('renders disabled buttons as not focusable (HTMLButtonElement.disabled === true)', () => {
      const steps = [
        { id: 1, label: 'Details' },
        { id: 2, label: 'Requirements', disabled: true },
      ];
      createComponent({ steps, currentStep: 1, listeners: { 'step-click': () => {} } });
      expect(findStepRoot(1).element.disabled).toBe(false);
      expect(findStepRoot(2).element.disabled).toBe(true);
    });

    it('marks the connector decoration aria-hidden so screen readers skip it', () => {
      createComponent();
      const connectors = wrapper.findAll('[aria-hidden="true"]');
      expect(connectors.length).toBeGreaterThan(0);
    });
  });

  describe('backward compatibility (no @step-click listener)', () => {
    beforeEach(() => createComponent());

    it('renders steps as non-interactive elements when no listener is attached', () => {
      baseSteps.forEach((step) => {
        const root = findStepRoot(step.id);
        expect(root.element.tagName).not.toBe('BUTTON');
      });
    });

    it('does not emit step-click when steps are clicked without a listener', async () => {
      await findStepRoot(2).trigger('click');
      expect(wrapper.emitted('step-click')).toBeUndefined();
    });
  });
});
