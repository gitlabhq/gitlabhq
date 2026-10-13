import {
  singleDatabaseResults,
  multiDatabaseResults,
} from 'jest/admin/database_diagnostics/mock_data';
import SchemaResultsContainer from './schema_results_container.vue';

export default {
  title: 'admin/database_diagnostics/components/schema_results_container',
  component: SchemaResultsContainer,
  argTypes: {
    schemaDiagnostics: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SchemaResultsContainer },
  template: '<schema-results-container v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = { schemaDiagnostics: singleDatabaseResults };

export const MultipleDatabases = Template.bind({});
MultipleDatabases.args = { schemaDiagnostics: multiDatabaseResults };
