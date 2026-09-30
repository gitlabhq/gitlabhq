import {
  collationMismatchResults,
  noIssuesResults,
} from 'jest/admin/database_diagnostics/mock_data';
import DbDiagnosticResults from './db_diagnostic_results.vue';

export default {
  title: 'admin/database_diagnostics/components/db_diagnostic_results',
  component: DbDiagnosticResults,
  argTypes: {
    dbName: { control: 'text' },
    dbDiagnosticResult: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbDiagnosticResults },
  template: '<db-diagnostic-results v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  dbName: 'main',
  dbDiagnosticResult: collationMismatchResults.databases.main,
};

// No corrupted indexes, so no remediation footer.
export const NoIssues = Template.bind({});
NoIssues.args = { dbName: 'main', dbDiagnosticResult: noIssuesResults.databases.main };
