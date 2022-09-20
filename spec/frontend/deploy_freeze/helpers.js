import freezePeriodsFixture from 'test_fixtures/api/freeze-periods/freeze_periods.json';
import timezoneDataFixture from 'test_fixtures/timezones/short.json';
import { formatUtcOffset } from '~/lib/utils/datetime_utility';

export { freezePeriodsFixture, timezoneDataFixture };

export const findTzByName = (identifier = '') =>
  timezoneDataFixture.find(({ name }) => name.toLowerCase() === identifier.toLowerCase());

export const formatTz = ({ offset, name }) => `[UTC ${formatUtcOffset(offset)}] ${name}`;
