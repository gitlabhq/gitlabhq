import { useFakeDate } from './jest';

// Also see spec/support/helpers/javascript_fixtures_helpers.rb
export const useFixturesFakeDate = () => useFakeDate(2015, 6, 3, 10);
