import { TYPENAME_ANALYTICS_CUSTOM_DASHBOARD } from '~/graphql_shared/constants';
import {
  getDashboardIdFromGraphQLId,
  convertToDashboardGraphQLId,
} from '~/explore/analytics_dashboards/utils';

const id = 3;
const gid = `gid://gitlab/${TYPENAME_ANALYTICS_CUSTOM_DASHBOARD}/${id}`;

describe('getDashboardIdFromGraphQLId', () => {
  it('extracts the numeric ID from a dashboard GraphQL global ID', () => {
    expect(getDashboardIdFromGraphQLId(gid)).toBe(id);
  });

  it('returns null for an empty string', () => {
    expect(getDashboardIdFromGraphQLId('')).toBeNull();
  });
});

describe('convertToDashboardGraphQLId', () => {
  it('converts a numeric ID to a dashboard GraphQL global ID', () => {
    expect(convertToDashboardGraphQLId(id)).toBe(gid);
  });

  it('converts a string ID to a dashboard GraphQL global ID', () => {
    expect(convertToDashboardGraphQLId(String(id))).toBe(gid);
  });
});
