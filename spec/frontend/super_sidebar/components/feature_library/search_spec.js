import { rankSearchResults } from '~/super_sidebar/components/feature_library/search';

describe('rankSearchResults', () => {
  const item = (id, title, description = '') => ({ id, title, description });

  const run = (catalog, query, synonymIds = []) =>
    rankSearchResults({ catalog, query, synonymIds }).map(({ id }) => id);

  it('orders title tiers before synonym before description', () => {
    const catalog = [
      item('desc', 'Alpha', 'mentions map here'),
      item('contains', 'Site map'),
      item('exact', 'Map'),
      item('prefix', 'Maps overview'),
      item('syn', 'Atlas'),
    ];

    expect(run(catalog, 'map', ['syn'])).toEqual(['exact', 'prefix', 'contains', 'syn', 'desc']);
  });

  it('prefers the shorter title within a title tier', () => {
    const catalog = [item('long', 'Merge request approvals'), item('short', 'Merge requests')];

    expect(run(catalog, 'merge')).toEqual(['short', 'long']);
  });

  it('keeps the endpoint order within the synonym tier, not alphabetical', () => {
    // Endpoint ranks 'zebra' first; neither title contains the query.
    const catalog = [item('ant', 'Ant'), item('zebra', 'Zebra')];

    expect(run(catalog, 'pr', ['zebra', 'ant'])).toEqual(['zebra', 'ant']);
  });

  it('keeps the description tier alphabetical, not length-ordered', () => {
    const catalog = [item('ci', 'CI', 'plan builds'), item('analytics', 'Analytics', 'plan usage')];

    expect(run(catalog, 'plan')).toEqual(['analytics', 'ci']);
  });

  it('does not surface an item twice when it matches both endpoint and title', () => {
    const catalog = [item('repo', 'Repository', 'code')];

    expect(run(catalog, 'repo', ['repo'])).toEqual(['repo']);
  });

  it('drops endpoint ids with no catalog entry', () => {
    const catalog = [item('repo', 'Repository')];

    expect(run(catalog, 'repo', ['ghost', 'repo'])).toEqual(['repo']);
  });
});
