import DataTable from './data_table.vue';
import MergeRequestLink from './merge_request_link.vue';

export default {
  component: MergeRequestLink,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/merge_request_link',
};

const Template = (args, { argTypes }) => ({
  components: { MergeRequestLink },
  props: Object.keys(argTypes),
  template: `
    <merge-request-link
      :iid="iid"
      :title="title"
      :webUrl="webUrl"
      :pipelineStatus="pipelineStatus"
      :labelsCount="labelsCount"
      :userNotesCount="userNotesCount"
      :approvalCount="approvalCount"
    />
  `,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = {
  iid: '111111',
  title: 'Merge request title',
  webUrl: 'https://gitlab.com',
  pipelineStatus: {
    name: 'SUCCESS',
    label: 'success',
  },
  labelsCount: 10,
  userNotesCount: 15,
  approvalCount: 1,
};

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      {
        mergeRequestLink: {
          iid: '123123',
          title: 'Merge request #1',
          webUrl: 'https://gitlab.com',
        },
      },
      {
        mergeRequestLink: {
          iid: '456456',
          title: 'Merge request #2',
          webUrl: 'https://gitlab.com',
          pipelineStatus: {
            name: 'PENDING',
            label: 'pending',
          },
          labelsCount: 3,
          userNotesCount: 33,
          approvalCount: 2,
        },
      },
      {
        mergeRequestLink: {
          iid: '789789',
          title: 'Merge request #3',
          webUrl: 'https://gitlab.com',
          pipelineStatus: {
            name: 'FAILED',
            label: 'failed',
          },
          labelsCount: 100,
          userNotesCount: 120,
          approvalCount: 10,
        },
      },
    ],
  },
  options: {
    fields: [{ key: 'mergeRequestLink', label: 'Merge request', component: 'MergeRequestLink' }],
  },
};
