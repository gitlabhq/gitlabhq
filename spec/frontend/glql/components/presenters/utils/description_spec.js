import {
  interpolateDescription,
  listDescriptionError,
  listDescriptionFor,
  placeholdersIn,
  unknownPlaceholderError,
} from '~/glql/components/presenters/utils/description';

const dimension = { key: 'language', label: 'Language', type: 'dimension' };
const totalCount = { key: 'totalCount', label: 'Total count', type: 'metric' };
const medianTimeToMerge = {
  key: 'Median',
  field: 'timeToMergeQuantile',
  label: 'Median',
  type: 'metric',
  parameters: { quantile: 0.5 },
};
const fields = [totalCount, medianTimeToMerge];

describe('placeholdersIn', () => {
  it.each`
    description                             | expected
    ${'%{totalCount} of %{Median}'}         | ${['totalCount', 'Median']}
    ${'Across %{p95 duration} per session'} | ${['p95 duration']}
    ${'Share of credits by capability'}     | ${[]}
    ${null}                                 | ${[]}
    ${undefined}                            | ${[]}
  `('returns $expected for $description', ({ description, expected }) => {
    expect(placeholdersIn(description)).toEqual(expected);
  });
});

describe('interpolateDescription', () => {
  it('fills each placeholder with its own metric formatted value', () => {
    expect(
      interpolateDescription('%{totalCount} merged, median %{Median}', fields, {
        totalCount: 2362,
        Median: 33840,
      }),
    ).toBe('2,362 merged, median 9h 24m');
  });

  it.each`
    case                         | row
    ${'the row leaves it null'}  | ${{ totalCount: null }}
    ${'the row omits it'}        | ${{}}
    ${'there is no row to read'} | ${undefined}
  `('renders the no-data placeholder when $case', ({ row }) => {
    expect(interpolateDescription('%{totalCount} sessions', fields, row)).toBe('— sessions');
  });

  it('leaves a placeholder for a field it was not given untouched', () => {
    expect(interpolateDescription('%{usersCount} users', fields, { totalCount: 1 })).toBe(
      '%{usersCount} users',
    );
  });

  it.each(['', null, undefined])('returns %p as is', (description) => {
    expect(interpolateDescription(description, fields, {})).toBe(description);
  });
});

describe('unknownPlaceholderError', () => {
  it('returns null when every placeholder names a metric', () => {
    expect(unknownPlaceholderError('%{totalCount} of %{Median}', fields)).toBeNull();
  });

  it('names the first placeholder the metrics do not include', () => {
    expect(unknownPlaceholderError('%{totalCount} of %{usersCount} and %{x}', fields)).toBe(
      'Unknown description placeholder: `usersCount`.',
    );
  });

  it('matches on the alias, not the base key', () => {
    expect(unknownPlaceholderError('%{timeToMergeQuantile}', fields)).toBe(
      'Unknown description placeholder: `timeToMergeQuantile`.',
    );
  });
});

describe('listDescriptionFor', () => {
  const description = '%{totalCount} sessions';

  it('interpolates the first row only', () => {
    expect(
      listDescriptionFor({
        description,
        fields: [dimension, totalCount],
        data: { nodes: [{ totalCount: 4 }, { totalCount: 172 }] },
        loading: false,
      }),
    ).toBe('4 sessions');
  });

  it('returns null while a placeholder description waits for the first row', () => {
    expect(listDescriptionFor({ description, fields, data: { nodes: [] }, loading: true })).toBe(
      null,
    );
  });

  it('returns a static description while loading', () => {
    expect(
      listDescriptionFor({ description: 'Sessions', fields, data: undefined, loading: true }),
    ).toBe('Sessions');
  });

  it('renders the no-data placeholder once loading ends with no rows', () => {
    expect(listDescriptionFor({ description, fields, data: { nodes: [] }, loading: false })).toBe(
      '— sessions',
    );
  });
});

describe('listDescriptionError', () => {
  it.each`
    case                                       | description                 | queryFields
    ${'a static description with a dimension'} | ${'Sessions'}               | ${[dimension, totalCount]}
    ${'placeholders without a dimension'}      | ${'%{totalCount} sessions'} | ${fields}
    ${'no description'}                        | ${undefined}                | ${[dimension, totalCount]}
  `('returns null for $case', ({ description, queryFields }) => {
    expect(listDescriptionError(description, queryFields)).toBeNull();
  });

  it('rejects a placeholder when the query has a dimension', () => {
    expect(listDescriptionError('%{totalCount} sessions', [dimension, totalCount])).toBe(
      'Description placeholders cannot be used with dimensions.',
    );
  });

  it('reports an unknown placeholder ahead of the dimension error', () => {
    expect(listDescriptionError('%{usersCount} users', [dimension, totalCount])).toBe(
      'Unknown description placeholder: `usersCount`.',
    );
  });
});
