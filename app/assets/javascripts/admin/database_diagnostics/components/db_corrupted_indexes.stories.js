import {
  collationMismatchResults,
  corruptedIndexesStructural,
} from 'jest/admin/database_diagnostics/mock_data';
import DbCorruptedIndexes from './db_corrupted_indexes.vue';

export default {
  title: 'admin/database_diagnostics/components/db_corrupted_indexes',
  component: DbCorruptedIndexes,
  argTypes: {
    corruptedIndexes: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbCorruptedIndexes },
  template: '<db-corrupted-indexes v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  corruptedIndexes: collationMismatchResults.databases.main.corrupted_indexes,
};

// Structural corruption is badged danger, duplicates warning, and one index
// can carry both.
export const StructuralCorruption = Template.bind({});
StructuralCorruption.args = { corruptedIndexes: corruptedIndexesStructural };

export const NoCorruption = Template.bind({});
NoCorruption.args = { corruptedIndexes: [] };
