import LoadingStateListItem from './loading_state_list_item.vue';

export default {
  component: LoadingStateListItem,
  title: 'vue_shared/resource_lists/loading_state_list_item',
  argTypes: {
    leftLinesCount: {
      control: { type: 'number', min: 0, max: 5, step: 1 },
      description: 'Number of skeleton lines to display on the left side',
      table: {
        type: { summary: 'number' },
        defaultValue: { summary: 2 },
      },
    },
    rightLinesCount: {
      control: { type: 'number', min: 0, max: 5, step: 1 },
      description: 'Number of skeleton lines to display on the right side (hidden on mobile)',
      table: {
        type: { summary: 'number' },
        defaultValue: { summary: 2 },
      },
    },
  },
  parameters: {
    docs: {
      description: {
        component:
          'A loading state list item component that displays skeleton loaders in a left-right layout. The right side content is hidden on mobile devices (below md breakpoint).',
      },
    },
    layout: 'padded',
  },
};

export const Default = {
  args: {
    leftLinesCount: 2,
    rightLinesCount: 2,
  },
};

export const LeftContentOnly = {
  args: {
    leftLinesCount: 2,
    rightLinesCount: 0,
  },
  parameters: {
    docs: {
      description: {
        story: 'Loading state with content only on the left side.',
      },
    },
  },
};
