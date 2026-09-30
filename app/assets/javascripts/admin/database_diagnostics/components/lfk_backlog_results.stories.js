import { lfkBacklogResults, lfkNoBacklogResults } from 'jest/admin/database_diagnostics/mock_data';
import LfkBacklogResults from './lfk_backlog_results.vue';

export default {
  title: 'admin/database_diagnostics/components/lfk_backlog_results',
  component: LfkBacklogResults,
  argTypes: {
    connectionName: { control: 'text' },
    backlog: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LfkBacklogResults },
  template: '<lfk-backlog-results v-bind="$props" />',
});

// The first row is capped, meaning the real count is at least the number
// shown; the second reports an exact count.
export const Default = Template.bind({});
Default.args = {
  connectionName: 'main',
  backlog: lfkBacklogResults.connections.main,
};

export const NoBacklog = Template.bind({});
NoBacklog.args = {
  connectionName: 'main',
  backlog: lfkNoBacklogResults.connections.main,
};
