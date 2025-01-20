import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from './multi_step_form_template.vue';

export default {
  component: MultiStepFormTemplate,
  title: 'vue_shared/multi_step_form_template',
  argTypes: {
    title: {
      control: 'text',
    },
    currentStep: {
      control: 'number',
    },
    stepsTotal: {
      control: 'number',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { MultiStepFormTemplate, GlButton },
  props: Object.keys(argTypes),
  template: `<multi-step-form-template v-bind="$props">
    <template #form>
      <div class="gl-flex gl-justify-center gl-items-center" style="height: 100px; border-radius: 8px; border: 1px dashed gray;">
        <code>#form</code> slot
      </div>
    </template>
    <template #back>
      <div class="gl-flex gl-justify-center gl-items-center" style="padding: 16px; border-radius: 8px; border: 1px dashed gray;">
        <code>#back</code> slot for a back button
      </div>
    </template>
    <template #next>
      <div class="gl-flex gl-justify-center gl-items-center" style="padding: 16px; border-radius: 8px; border: 1px dashed gray;">
        <code>#next</code> slot for a next button
      </div>
    </template>
    <template #footer>
      <div class="gl-flex gl-justify-center gl-items-center" style="height: 100px; border-radius: 8px; border: 1px dashed gray;">
        <code>#footer</code> slot
      </div>
    </template>
  </multi-step-form-template>`,
});

export const Default = Template.bind({});
Default.args = {
  title: 'Create new project',
  currentStep: 1,
  stepsTotal: 2,
};
export const NumberOfStepsIsNotDefined = Template.bind({});
NumberOfStepsIsNotDefined.args = {
  title: 'Create new project',
  currentStep: 1,
};
