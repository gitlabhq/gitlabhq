export default ({
  projectId,
  freezePeriods = [],
  timezoneData = [],
  selectedTimezone = '',
  selectedTimezoneIdentifier = '',
  freezeStartCron = '',
  freezeEndCron = '',
}) => ({
  projectId,
  freezePeriods,
  timezoneData,
  selectedTimezone,
  selectedTimezoneIdentifier,
  freezeStartCron,
  freezeEndCron,
});
