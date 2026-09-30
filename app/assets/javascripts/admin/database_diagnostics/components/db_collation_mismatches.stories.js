import { collationMismatchResults } from 'jest/admin/database_diagnostics/mock_data';
import DbCollationMismatches from './db_collation_mismatches.vue';

export default {
  title: 'admin/database_diagnostics/components/db_collation_mismatches',
  component: DbCollationMismatches,
  argTypes: {
    collationMismatches: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbCollationMismatches },
  template: '<db-collation-mismatches v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  collationMismatches: collationMismatchResults.databases.main.collation_mismatches,
};

export const NoMismatches = Template.bind({});
NoMismatches.args = { collationMismatches: [] };
