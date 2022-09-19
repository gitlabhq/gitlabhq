import InputCopyToggleVisibility from './input_copy_toggle_visibility.vue';

export default {
  component: InputCopyToggleVisibility,
  title: 'vue_shared/form/input_copy_toggle_visibility',
};

const defaultProps = {
  value: 'hR8x1fuJbzwu5uFKLf9e',
  formInputGroupProps: { class: 'gl-form-input-xl' },
};

const Template = (args, { argTypes }) => ({
  components: { InputCopyToggleVisibility },
  props: Object.keys(argTypes),
  template: `<input-copy-toggle-visibility
      :value="value" 
      :initial-visibility="initialVisibility"
      :show-toggle-visibility-button="showToggleVisibilityButton"
      :show-copy-button="showCopyButton"
      :form-input-group-props="formInputGroupProps"
      :copy-button-title="copyButtonTitle"
    />`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
