import ViewSourceModal from './view_source_modal.vue';

const QUERY_YAML = `display: list
title: My open issues
description: This view lists my open issues
limit: 5
query: assignee = currentUser() AND state = opened`;

export default {
  component: ViewSourceModal,
  title: 'glql/components/common/view_source_modal',
  argTypes: {
    query: {
      control: 'text',
      description: 'YAML source of the query, rendered wrapped in a GLQL code block.',
    },
    title: {
      control: 'text',
      description: 'Modal heading. Falls back to an empty heading when the view has no title.',
    },
    visible: { control: 'boolean' },

    // events
    change: { action: 'change' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ViewSourceModal },
  props: Object.keys(argTypes),
  template: `<view-source-modal
    :query="query"
    :title="title"
    :visible="visible"
    v-on="{ change }"
  />`,
});

export const Default = Template.bind({});
Default.args = {
  query: QUERY_YAML,
  title: 'My open issues',
  visible: true,
};

// The title is optional, so the modal has to stay readable without a heading.
export const WithoutTitle = Template.bind({});
WithoutTitle.args = {
  ...Default.args,
  title: '',
};

export const SingleLineQuery = Template.bind({});
SingleLineQuery.args = {
  ...Default.args,
  query: 'query: assignee = currentUser()',
};
