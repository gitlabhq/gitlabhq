import { secondsToHours } from '~/lib/utils/datetime_utility';

export const freezePeriodsFixture = getJSONFixture('/api/freeze-periods/freeze_periods.json');
export const timezoneDataFixture = getJSONFixture('/timezones/short.json');

export const findTzByName = (identifier = '') =>
  timezoneDataFixture.find(({ name }) => name.toLowerCase() === identifier.toLowerCase());

export const formatTz = ({ offset, name }) => `[UTC ${secondsToHours(offset)}] ${name}`;
