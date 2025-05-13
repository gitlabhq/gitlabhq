import ColorPicker from './color_picker.vue';

const propDefault = (prop) => {
  const defaultValue = ColorPicker.props[prop].default;

  return typeof defaultValue === 'function' ? defaultValue() : defaultValue;
};

const makeStory = ({ props } = {}) => {
  const Story = (args, { argTypes }) => ({
    components: { ColorPicker },
    props: Object.keys(argTypes),
    template: '<color-picker v-bind="$props" />',
  });

  Story.args = {
    ...Object.fromEntries(Object.keys(ColorPicker.props).map((prop) => [prop, propDefault(prop)])),
    suggestedColors: {},
    ...props,
  };

  return Story;
};

export const Default = makeStory();

export const InvalidState = makeStory({
  props: {
    value: 'foo',
    state: false,
  },
});

export default {
  component: ColorPicker,
  title: 'vue_shared/components/color_picker',
};
