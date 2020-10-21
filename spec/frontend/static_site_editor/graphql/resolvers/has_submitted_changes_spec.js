import appDataQuery from '~/static_site_editor/graphql/queries/app_data.query.graphql';
import hasSubmittedChanges from '~/static_site_editor/graphql/resolvers/has_submitted_changes';

describe('static_site_editor/graphql/resolvers/has_submitted_changes', () => {
  it('updates the cache with the data passed in input', () => {
    const cachedData = { appData: { original: 'foo' } };
    const newValue = { input: { hasSubmittedChanges: true } };

    const cache = {
      readQuery: jest.fn().mockReturnValue(cachedData),
      writeQuery: jest.fn(),
    };
    hasSubmittedChanges(null, newValue, { cache });

    expect(cache.readQuery).toHaveBeenCalledWith({ query: appDataQuery });
    expect(cache.writeQuery).toHaveBeenCalledWith({
      query: appDataQuery,
      data: {
        appData: {
          __typename: 'AppData',
          original: 'foo',
          hasSubmittedChanges: true,
        },
      },
    });
  });
});
