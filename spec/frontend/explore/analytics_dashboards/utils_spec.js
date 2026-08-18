import { TYPENAME_ANALYTICS_CUSTOM_DASHBOARD } from '~/graphql_shared/constants';
import {
  getDashboardIdFromGraphQLId,
  convertToDashboardGraphQLId,
  buildDocumentTitle,
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

describe('buildDocumentTitle', () => {
  const baseTitle = 'Analytics dashboards · GitLab';
  const buildRoute = (meta) => ({ meta });

  it('returns the base title unchanged for the root route', () => {
    expect(buildDocumentTitle(buildRoute({ root: true }), baseTitle)).toBe(baseTitle);
  });

  it('prepends the route name for a route without parents', () => {
    const route = buildRoute({ getName: () => 'My dashboard' });

    expect(buildDocumentTitle(route, baseTitle)).toBe(`My dashboard · ${baseTitle}`);
  });

  it('prepends parent segments deepest-first', () => {
    const route = buildRoute({
      getName: () => 'Edit',
      getParents: () => [{ text: 'My dashboard', to: '/3' }],
    });

    expect(buildDocumentTitle(route, baseTitle)).toBe(`Edit · My dashboard · ${baseTitle}`);
  });

  it('drops empty segments while the dashboard name is still loading', () => {
    const route = buildRoute({ getName: () => '' });

    expect(buildDocumentTitle(route, baseTitle)).toBe(baseTitle);
  });

  it('returns the base title when the route has no metadata', () => {
    expect(buildDocumentTitle(buildRoute({}), baseTitle)).toBe(baseTitle);
  });
});
