import { collationMismatchResults } from 'jest/admin/database_diagnostics/mock_data';
import DbSkippedIndexes from './db_skipped_indexes.vue';

export default {
  title: 'admin/database_diagnostics/components/db_skipped_indexes',
  component: DbSkippedIndexes,
  argTypes: {
    skippedIndexes: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbSkippedIndexes },
  template: '<db-skipped-indexes v-bind="$props" />',
});

// With nothing to report the section removes itself, so there is no empty state
// to show here.
export const Default = Template.bind({});
Default.args = {
  skippedIndexes: collationMismatchResults.databases.main.skipped_indexes,
};
