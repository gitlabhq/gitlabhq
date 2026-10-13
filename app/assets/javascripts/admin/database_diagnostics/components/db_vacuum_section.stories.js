import {
  vacuumActivity,
  vacuumActivityAntiWraparound,
  vacuumActivityWithoutPgMonitor,
} from 'jest/admin/database_diagnostics/mock_data';
import DbVacuumSection from './db_vacuum_section.vue';

export default {
  title: 'admin/database_diagnostics/components/db_vacuum_section',
  component: DbVacuumSection,
  argTypes: {
    vacuums: { control: false, description: 'Rows from pg_stat_progress_vacuum.' },
    activityAvailable: {
      control: 'boolean',
      description: 'False when the role cannot read pg_stat_activity.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DbVacuumSection },
  template: '<db-vacuum-section v-bind="$props" />',
});

// The first row has run for ten hours and has taken more than one index pass,
// so it carries both the long-running and the memory pressure badge.
export const Default = Template.bind({});
Default.args = { vacuums: vacuumActivity };

export const NoActivity = Template.bind({});
NoActivity.args = { vacuums: [] };

// An anti-wraparound vacuum will not auto-cancel and must not be terminated
// casually, so it is called out explicitly.
export const AntiWraparound = Template.bind({});
AntiWraparound.args = { vacuums: vacuumActivityAntiWraparound };

// Without pg_monitor the type, running time and anti-wraparound status cannot
// be read, so those cells fall back to Not available.
export const ActivityUnavailable = Template.bind({});
ActivityUnavailable.args = {
  vacuums: vacuumActivityWithoutPgMonitor,
  activityAvailable: false,
};
