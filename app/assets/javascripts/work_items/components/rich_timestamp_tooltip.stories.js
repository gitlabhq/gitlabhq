import RichTimestampTooltip from './rich_timestamp_tooltip.vue';

export default {
  component: RichTimestampTooltip,
  title: 'work_items/rich_timestamp_tooltip',
};

const Template = (args, { argTypes }) => ({
  components: { RichTimestampTooltip },
  props: Object.keys(argTypes),

  template: `
   <div>
    <span ref="targetElement">example text</span>
    <rich-timestamp-tooltip :target="() => $refs.targetElement" v-bind="$props" />
  </div>`,
});

export const Default = Template.bind({});
Default.args = {
  rawTimestamp: '2023-10-26T14:32:12.000Z',
  timestampTypeText: 'Created',
};
