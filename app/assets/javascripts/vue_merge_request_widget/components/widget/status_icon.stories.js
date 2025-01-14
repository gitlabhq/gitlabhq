import { EXTENSION_ICON_CLASS } from '../../constants';
import StatusIcon from './status_icon.vue';

export default {
  title: 'merge_request_widget/status_icon',
  component: StatusIcon,
  argTypes: {
    level: { control: { type: 'select', options: [1, 2, 3] } },
    iconName: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  variants: Object.keys(EXTENSION_ICON_CLASS),
  props: Object.keys(argTypes),
  components: { StatusIcon },
  template: `
    <div class="gl-flex">
      <status-icon
        v-for="variant in $options.variants"
        :name="name"
        :icon-name="variant"
        :level="level"
        :is-loading="isLoading"
      />
    </div>
  `,
});

export const LevelOne = Template.bind({});
LevelOne.args = {
  level: 1,
  name: 'Status',
  isLoading: false,
  iconName: 'success',
};

export const LevelTwo = Template.bind({});
LevelTwo.args = {
  ...LevelOne.args,
  level: 2,
};

export const LevelThree = Template.bind({});
LevelThree.args = {
  ...LevelOne.args,
  level: 3,
};
