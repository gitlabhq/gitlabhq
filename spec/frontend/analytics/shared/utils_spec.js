import { filterBySearchTerm } from '~/analytics/shared/utils';

describe('filterBySearchTerm', () => {
  const data = [
    { name: 'eins', title: 'one' },
    { name: 'zwei', title: 'two' },
    { name: 'drei', title: 'three' },
  ];
  const searchTerm = 'rei';

  it('filters data by `name` for the provided search term', () => {
    expect(filterBySearchTerm(data, searchTerm)).toEqual([data[2]]);
  });

  it('with no search term returns the data', () => {
    ['', null].forEach((search) => {
      expect(filterBySearchTerm(data, search)).toEqual(data);
    });
  });

  it('with a key, filters by the provided key', () => {
    expect(filterBySearchTerm(data, 'ne', 'title')).toEqual([data[0]]);
  });
});
