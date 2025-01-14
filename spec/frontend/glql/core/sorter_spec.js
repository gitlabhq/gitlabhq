import Sorter, { sorterFor } from '~/glql/core/sorter';

describe('sorterFor', () => {
  it('sorts by string property', () => {
    const items = [{ name: 'Charlie' }, { name: 'Alice' }, { name: 'Bob' }];

    expect(items.sort(sorterFor('name'))).toEqual([
      { name: 'Alice' },
      { name: 'Bob' },
      { name: 'Charlie' },
    ]);

    expect(items.sort(sorterFor('name', false))).toEqual([
      { name: 'Charlie' },
      { name: 'Bob' },
      { name: 'Alice' },
    ]);
  });

  it('sorts by number property', () => {
    const items = [{ age: 30 }, { age: 25 }, { age: 35 }];

    expect(items.sort(sorterFor('age'))).toEqual([{ age: 25 }, { age: 30 }, { age: 35 }]);
    expect(items.sort(sorterFor('age', false))).toEqual([{ age: 35 }, { age: 30 }, { age: 25 }]);
  });

  it('sorts by date string', () => {
    const items = [{ date: '2023-06-01' }, { date: '2023-05-15' }, { date: '2023-06-15' }];

    expect(items.sort(sorterFor('date'))).toEqual([
      { date: '2023-05-15' },
      { date: '2023-06-01' },
      { date: '2023-06-15' },
    ]);

    expect(items.sort(sorterFor('date', false))).toEqual([
      { date: '2023-06-15' },
      { date: '2023-06-01' },
      { date: '2023-05-15' },
    ]);
  });

  it('sorts by health status', () => {
    const items = [
      { healthStatus: 'atRisk' },
      { healthStatus: 'onTrack' },
      { healthStatus: 'needsAttention' },
    ];

    expect(items.sort(sorterFor('healthStatus'))).toEqual([
      { healthStatus: 'onTrack' },
      { healthStatus: 'needsAttention' },
      { healthStatus: 'atRisk' },
    ]);

    expect(items.sort(sorterFor('healthStatus', false))).toEqual([
      { healthStatus: 'atRisk' },
      { healthStatus: 'needsAttention' },
      { healthStatus: 'onTrack' },
    ]);
  });

  it('sorts by state', () => {
    const items = [
      { state: 'closed' },
      { state: 'opened' },
      { state: 'closed' },
      { state: 'merged' },
    ];

    expect(items.sort(sorterFor('state'))).toEqual([
      { state: 'opened' },
      { state: 'closed' },
      { state: 'closed' },
      { state: 'merged' },
    ]);

    expect(items.sort(sorterFor('state', false))).toEqual([
      { state: 'merged' },
      { state: 'closed' },
      { state: 'closed' },
      { state: 'opened' },
    ]);
  });

  it('handles null values: they are always pushed to the bottom regardless of the order', () => {
    const items = [{ value: 'B' }, { value: null }, { value: 'A' }, { value: null }];
    expect(items.sort(sorterFor('value'))).toEqual([
      { value: 'A' },
      { value: 'B' },
      { value: null },
      { value: null },
    ]);

    expect(items.sort(sorterFor('value', false))).toEqual([
      { value: 'B' },
      { value: 'A' },
      { value: null },
      { value: null },
    ]);
  });

  it('sorts by custom type (__typename = Epic)', () => {
    const items = [
      { epic: { __typename: 'Epic', title: 'Epic C' } },
      { epic: { __typename: 'Epic', title: 'Epic A' } },
      { epic: { __typename: 'Epic', title: 'Epic B' } },
    ];

    expect(items.sort(sorterFor('epic'))).toEqual([
      { epic: { __typename: 'Epic', title: 'Epic A' } },
      { epic: { __typename: 'Epic', title: 'Epic B' } },
      { epic: { __typename: 'Epic', title: 'Epic C' } },
    ]);

    expect(items.sort(sorterFor('epic', false))).toEqual([
      { epic: { __typename: 'Epic', title: 'Epic C' } },
      { epic: { __typename: 'Epic', title: 'Epic B' } },
      { epic: { __typename: 'Epic', title: 'Epic A' } },
    ]);
  });

  it('sorts by custom type (__typename = UserCore)', () => {
    const items = [
      { author: { __typename: 'UserCore', username: 'jane' } },
      { author: { __typename: 'UserCore', username: 'jill' } },
      { author: { __typename: 'UserCore', username: 'adam' } },
    ];

    expect(items.sort(sorterFor('author'))).toEqual([
      { author: { __typename: 'UserCore', username: 'adam' } },
      { author: { __typename: 'UserCore', username: 'jane' } },
      { author: { __typename: 'UserCore', username: 'jill' } },
    ]);

    expect(items.sort(sorterFor('author', false))).toEqual([
      { author: { __typename: 'UserCore', username: 'jill' } },
      { author: { __typename: 'UserCore', username: 'jane' } },
      { author: { __typename: 'UserCore', username: 'adam' } },
    ]);
  });

  it('sorts by a field that is a collection of items', () => {
    const items = [
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'C' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
    ];

    expect(items.sort(sorterFor('labels'))).toEqual([
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'C' }, { title: 'A' }] } },
    ]);

    expect(items.sort(sorterFor('labels', false))).toEqual([
      { labels: { nodes: [{ title: 'C' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
    ]);
  });

  it('always sorts empty collections to the end', () => {
    const items = [
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [] } },
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
    ];

    expect(items.sort(sorterFor('labels'))).toEqual([
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [] } },
    ]);

    expect(items.sort(sorterFor('labels', false))).toEqual([
      { labels: { nodes: [{ title: 'B' }, { title: 'A' }] } },
      { labels: { nodes: [{ title: 'A' }, { title: 'B' }] } },
      { labels: { nodes: [] } },
    ]);
  });
});

describe('Sorter', () => {
  let items;
  let sorter;

  beforeEach(() => {
    items = [
      { id: 3, name: 'Charlie', age: 30 },
      { id: 1, name: 'Alice', age: 25 },
      { id: 2, name: 'Bob', age: 35 },
    ];
    sorter = new Sorter(items);
  });

  it('initializes with items', () => {
    expect(sorter.options).toEqual({ fieldName: null, ascending: true });
  });

  it('sorts by field in ascending order', () => {
    const sorted = sorter.sortBy('name');
    expect(sorted.map((item) => item.name)).toEqual(['Alice', 'Bob', 'Charlie']);
    expect(sorter.options).toEqual({ fieldName: 'name', ascending: true });
  });

  it('sorts by field in descending order when called twice', () => {
    sorter.sortBy('name');
    const sorted = sorter.sortBy('name');
    expect(sorted.map((item) => item.name)).toEqual(['Charlie', 'Bob', 'Alice']);
    expect(sorter.options).toEqual({ fieldName: 'name', ascending: false });
  });

  it('sorts by different field resets ascending order', () => {
    sorter.sortBy('name');
    const sorted = sorter.sortBy('age');
    expect(sorted.map((item) => item.age)).toEqual([25, 30, 35]);
    expect(sorter.options).toEqual({ fieldName: 'age', ascending: true });
  });

  it('maintains original order for equal values', () => {
    items = [
      { id: 3, name: 'Alice', age: 30 },
      { id: 1, name: 'Alice', age: 25 },
      { id: 2, name: 'Alice', age: 35 },
    ];
    sorter = new Sorter(items);
    const sorted = sorter.sortBy('name');
    expect(sorted.map((item) => item.id)).toEqual([3, 1, 2]);
  });
});
