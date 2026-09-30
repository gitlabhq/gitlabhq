import {
  databaseInformationResults,
  databaseInformationWithFindings,
  databaseInformationWithDatabaseError,
} from 'jest/admin/database_diagnostics/mock_data';
import DbInformationCard from './db_information_card.vue';

const mainPayload = databaseInformationResults.databases.main;
const { timeouts, ...payloadWithoutTimeouts } = mainPayload;

export default {
  title: 'admin/database_diagnostics/components/db_information_card',
  component: DbInformationCard,
  parameters: {
    docs: {
      description: {
        component:
          'One card per database, holding the search path, timeouts and schemas sections. Each section starts collapsed.',
      },
    },
  },
  argTypes: {
    dbName: { control: 'text' },
    payload: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbInformationCard },
  template: '<db-information-card v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = { dbName: 'main', payload: mainPayload };

// Findings render as alerts above the current user and search path line.
export const WithFindings = Template.bind({});
WithFindings.args = {
  dbName: 'main',
  payload: databaseInformationWithFindings.databases.main,
};

// A database that could not be read at all: one warning alert, and every
// section suppressed.
export const DatabaseError = Template.bind({});
DatabaseError.args = {
  dbName: 'main',
  payload: databaseInformationWithDatabaseError.databases.main,
};

// The timeouts section is only rendered when the check reported a payload.
export const WithoutTimeouts = Template.bind({});
WithoutTimeouts.args = { dbName: 'main', payload: payloadWithoutTimeouts };
