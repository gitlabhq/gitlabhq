import HumanTimeframe from './human_timeframe.vue';

export default {
  component: HumanTimeframe,
  title: 'vue_shared/datetime/human_timeframe',
  argTypes: {
    from: {
      control: 'text',
      description: 'Start date in ISO string format',
    },
    till: {
      control: 'text',
      description: 'End date in ISO string format',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { HumanTimeframe },
  props: Object.keys(argTypes),
  template: '<HumanTimeframe v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  from: '2024-01-01T00:00:00Z',
  till: '2024-01-31T23:59:59Z',
};

export const SameMonth = Template.bind({});
SameMonth.args = {
  from: '2024-06-01T00:00:00Z',
  till: '2024-06-15T23:59:59Z',
};

export const CrossYear = Template.bind({});
CrossYear.args = {
  from: '2023-12-15T00:00:00Z',
  till: '2024-02-28T23:59:59Z',
};

export const Onlyfrom = Template.bind({});
Onlyfrom.args = {
  from: '2024-03-15T00:00:00Z',
  till: '',
};

export const OnlyEndDate = Template.bind({});
OnlyEndDate.args = {
  from: '',
  till: '2024-12-25T23:59:59Z',
};

export const SingleDay = Template.bind({});
SingleDay.args = {
  from: '2024-07-04T00:00:00Z',
  till: '2024-07-04T23:59:59Z',
};

export const UsingDateObjects = Template.bind({});
UsingDateObjects.argTypes = {
  from: {
    control: 'date',
    description: 'Start date as Date object',
  },
  till: {
    control: 'date',
    description: 'Due date as Date object',
  },
};
UsingDateObjects.args = {
  from: new Date(2024, 6, 4), // July 4, 2024
  till: new Date(2025, 6, 5), // July 5, 2024
};
