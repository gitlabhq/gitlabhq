import { mockMilestone } from 'jest/boards/mock_data';
import IssueMilestone from './issue_milestone.vue';

export default {
  component: IssueMilestone,
  title: 'issuable/issue/issue_milestone',
};

const Template = (args, { argTypes }) => ({
  components: { IssueMilestone },
  props: Object.keys(argTypes),
  template: '<issue-milestone v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  milestone: mockMilestone,
};

export const BeforeDueDate = Template.bind({});
BeforeDueDate.args = {
  milestone: {
    ...mockMilestone,
    due_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
  },
};
