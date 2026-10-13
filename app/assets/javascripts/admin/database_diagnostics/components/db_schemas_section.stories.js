import { databaseInformationResults } from 'jest/admin/database_diagnostics/mock_data';
import DbSchemasSection from './db_schemas_section.vue';

export default {
  title: 'admin/database_diagnostics/components/db_schemas_section',
  component: DbSchemasSection,
  argTypes: {
    schemas: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbSchemasSection },
  template: '<db-schemas-section v-bind="$props" />',
});

// The schema the connection resolves to first carries the Current badge.
export const Default = Template.bind({});
Default.args = { schemas: databaseInformationResults.databases.main.schemas };
