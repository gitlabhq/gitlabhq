import { TYPENAME_ANALYTICS_CUSTOM_DASHBOARD } from '~/graphql_shared/constants';
import {
  assignLoadPriority,
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

describe('assignLoadPriority', () => {
  const panel = (key, gridAttributes) => ({ id: key, title: `Panel `, gridAttributes });

  it('numbers panels in reading order, rows before columns, without reordering them', () => {
    const panels = [
      panel('a', { xPos: 0, yPos: 1, width: 6, height: 1 }),
      panel('b', { xPos: 6, yPos: 0, width: 6, height: 1 }),
      panel('c', { xPos: 0, yPos: 0, width: 6, height: 1 }),
    ];

    expect(assignLoadPriority(panels)).toEqual([
      { ...panels[0], loadPriority: 2 },
      { ...panels[1], loadPriority: 1 },
      { ...panels[2], loadPriority: 0 },
    ]);
  });

  it('sorts a panel without a position as the top left, keeping config order for ties', () => {
    const panels = [
      panel('positioned', { xPos: 0, yPos: 1, width: 6, height: 1 }),
      panel('sized-only', { width: 6, height: 3 }),
      panel('no-grid', undefined),
    ];

    expect(assignLoadPriority(panels).map(({ loadPriority }) => loadPriority)).toEqual([2, 0, 1]);
  });

  it('returns an empty array for no panels', () => {
    expect(assignLoadPriority()).toEqual([]);
  });
});
