import {
  timeouts,
  timeoutsWithoutFindings,
  timeoutsUnlimited,
  timeoutsAboveMaximum,
  timeoutsFromConfigurationFile,
  timeoutsWithOverrides,
  timeoutsWithoutSettings,
} from 'jest/admin/database_diagnostics/mock_data';
import DbTimeoutsSection from './db_timeouts_section.vue';

export default {
  title: 'admin/database_diagnostics/components/db_timeouts_section',
  component: DbTimeoutsSection,
  parameters: {
    docs: {
      description: {
        component:
          'Reports the session value and the cluster default for statement_timeout, lock_timeout and idle_in_transaction_session_timeout. Details start collapsed, so use the Details toggle to reveal the tables.',
      },
    },
  },
  argTypes: {
    timeouts: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbTimeoutsSection },
  template: '<db-timeouts-section v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = { timeouts };

export const NoFindings = Template.bind({});
NoFindings.args = { timeouts: timeoutsWithoutFindings };

// statement_timeout is 0 on GitLab's own connection, the one case the check
// treats as an error.
export const SessionUnlimited = Template.bind({});
SessionUnlimited.args = { timeouts: timeoutsUnlimited };

export const AboveRecommendedMaximum = Template.bind({});
AboveRecommendedMaximum.args = { timeouts: timeoutsAboveMaximum };

// sourcefile:sourceline renders next to the source so an admin knows which
// file to edit.
export const FromConfigurationFile = Template.bind({});
FromConfigurationFile.args = { timeouts: timeoutsFromConfigurationFile };

// pg_db_role_setting defaults get a second table, because pg_settings folds
// them into one resolved value. A missing role or database renders as All.
// There is no cluster default finding here: an override makes reset_val a poor
// guide to what other roles get, so the check stays quiet.
export const WithRoleAndDatabaseOverrides = Template.bind({});
WithRoleAndDatabaseOverrides.args = { timeouts: timeoutsWithOverrides };

export const NoSettingsRead = Template.bind({});
NoSettingsRead.args = { timeouts: timeoutsWithoutSettings };
