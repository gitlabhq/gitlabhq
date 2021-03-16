export default ({
  projectId,
  freezePeriods = [],
  timezoneData = [],
  selectedTimezone = '',
  selectedTimezoneIdentifier = '',
  freezeStartCron = '',
  freezeEndCron = '',
  selectedId = '',
}) => ({
  projectId,
  freezePeriods,
  timezoneData,
  selectedTimezone,
  selectedTimezoneIdentifier,
  freezeStartCron,
  freezeEndCron,
  selectedId,
});
