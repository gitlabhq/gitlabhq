import WizardStepper from './wizard_stepper.vue';

export default {
  component: WizardStepper,
  title: 'vue_shared/wizard_stepper',
};

const baseSteps = [
  { id: 1, label: 'Details' },
  { id: 2, label: 'Requirements' },
  { id: 3, label: 'Projects' },
  { id: 4, label: 'Review' },
];

const Template = (args, { argTypes }) => ({
  components: { WizardStepper },
  props: Object.keys(argTypes),
  template: '<wizard-stepper :steps="steps" :current-step="currentStep" />',
});

export const Default = Template.bind({});
Default.args = {
  steps: baseSteps,
  currentStep: 2,
};

export const FirstStep = Template.bind({});
FirstStep.args = {
  steps: baseSteps,
  currentStep: 1,
};

export const LastStep = Template.bind({});
LastStep.args = {
  steps: baseSteps,
  currentStep: 4,
};

export const WithDisabledStep = Template.bind({});
WithDisabledStep.args = {
  steps: [
    { id: 1, label: 'Details' },
    { id: 2, label: 'Requirements' },
    { id: 3, label: 'Projects', disabled: true },
    { id: 4, label: 'Review', disabled: true },
  ],
  currentStep: 2,
};

export const WithErrorStep = Template.bind({});
WithErrorStep.args = {
  steps: [
    { id: 1, label: 'Details', error: true, errorMessage: 'Name is required' },
    { id: 2, label: 'Requirements' },
    { id: 3, label: 'Projects' },
    { id: 4, label: 'Review' },
  ],
  currentStep: 2,
};

const ClickableTemplate = (args, { argTypes }) => ({
  components: { WizardStepper },
  props: Object.keys(argTypes),
  data() {
    return { lastClickedId: null };
  },
  template: `
    <div>
      <wizard-stepper :steps="steps" :current-step="currentStep" @step-click="lastClickedId = $event" />
      <p>Last clicked step id: {{ lastClickedId === null ? '(none)' : lastClickedId }}</p>
    </div>
  `,
});

export const Clickable = ClickableTemplate.bind({});
Clickable.args = {
  steps: baseSteps,
  currentStep: 2,
};
