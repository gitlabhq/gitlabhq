import InputCopyToggleVisibility from './input_copy_toggle_visibility.vue';

export default {
  component: InputCopyToggleVisibility,
  title: 'vue_shared/input_copy_toggle_visibility',
};

const defaultProps = {
  value: 'hR8x1fuJbzwu5uFKLf9e',
  formInputGroupProps: { class: 'gl-form-input-xl' },
  readonly: false,
};

const Template = (args, { argTypes }) => ({
  components: { InputCopyToggleVisibility },
  data() {
    return { value: args.value };
  },
  props: Object.keys(argTypes),
  template: `<input-copy-toggle-visibility
      v-model="value"
      :initial-visibility="initialVisibility"
      :show-toggle-visibility-button="showToggleVisibilityButton"
      :show-copy-button="showCopyButton"
      :readonly="readonly"
      :form-input-group-props="formInputGroupProps"
      :copy-button-title="copyButtonTitle"
      invalid-feedback="Oh no, there is some validation error"
    />`,
});

export const Default = Template.bind({});
Default.args = defaultProps;

export const WithValidationError = Template.bind({});
WithValidationError.args = {
  ...defaultProps,
  formInputGroupProps: { state: false },
};
WithValidationError.parameters = {
  docs: {
    description: {
      story:
        'An invalid state can be set on the component by providing a message via `:invalid-feedback`, and managing the input validity via `formInputGroupProps.state`, like other `<gl-form-input>`s',
    },
  },
};
