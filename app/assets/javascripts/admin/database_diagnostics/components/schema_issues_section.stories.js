import {
  schemaIssuesResults,
  noSchemaIssuesResults,
  singleDatabaseResults,
} from 'jest/admin/database_diagnostics/mock_data';
import SchemaIssuesSection from './schema_issues_section.vue';

export default {
  title: 'admin/database_diagnostics/components/schema_issues_section',
  component: SchemaIssuesSection,
  parameters: {
    docs: {
      description: {
        component:
          'Missing indexes, tables, foreign keys and sequences for one database. Every section starts collapsed, so use the toggles to reveal the lists.',
      },
    },
  },
  argTypes: {
    databaseResults: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SchemaIssuesSection },
  template: '<schema-issues-section v-bind="$props" />',
});

// All four sections populated. Sequences holds two subsections: missing
// sequences as a list, and incorrect ownership as a table.
export const Default = Template.bind({});
Default.args = { databaseResults: schemaIssuesResults.schema_check_results.main };

export const NoIssues = Template.bind({});
NoIssues.args = { databaseResults: noSchemaIssuesResults.schema_check_results.main };

// Only one section has issues, so the other three show the success icon.
export const SingleIssueType = Template.bind({});
SingleIssueType.args = { databaseResults: singleDatabaseResults.schema_check_results.main };
