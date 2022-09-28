import timezoneDataFixture from 'test_fixtures/timezones/short.json';

export { timezoneDataFixture };

export const findTzByName = (identifier = '') =>
  timezoneDataFixture.find(({ name }) => name.toLowerCase() === identifier.toLowerCase());
