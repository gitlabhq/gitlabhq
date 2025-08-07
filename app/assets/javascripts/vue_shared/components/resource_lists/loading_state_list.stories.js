import LoadingStateList from './loading_state_list.vue';

export default {
  component: LoadingStateList,
  title: 'vue_shared/resource_lists/loading_state_list',
  argTypes: {
    listLength: {
      control: { type: 'number', min: 1, max: 20, step: 1 },
      description: 'Number of loading items to display in the list',
      table: {
        type: { summary: 'number' },
        defaultValue: { summary: 5 },
      },
    },
    leftLinesCount: {
      control: { type: 'number', min: 0, max: 5, step: 1 },
      description: 'Number of skeleton lines to show on the left side of each item',
      table: {
        type: { summary: 'number' },
        defaultValue: { summary: 2 },
      },
    },
    rightLinesCount: {
      control: { type: 'number', min: 0, max: 5, step: 1 },
      description:
        'Number of skeleton lines to show on the right side of each item (hidden on mobile)',
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
          'A loading skeleton list component that displays multiple loading state items. Useful for showing loading states in list-based UIs.',
      },
    },
  },
};

export const Default = {
  args: {
    listLength: 5,
    leftLinesCount: 2,
    rightLinesCount: 2,
  },
};

export const AsymmetricLineCounts = {
  args: {
    listLength: 3,
    leftLinesCount: 3,
    rightLinesCount: 1,
  },
  parameters: {
    docs: {
      description: {
        story: 'Loading state for complex list items with more content on each side.',
      },
    },
  },
};

export const LeftContentOnly = {
  args: {
    listLength: 3,
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
