import { parseGetProjectStorageResults } from '~/projects/storage_counter/utils';
import {
  mockGetProjectStorageCountGraphQLResponse,
  projectData,
  defaultProvideValues,
} from './mock_data';

describe('parseGetProjectStorageResults', () => {
  it('parses project statistics correctly', () => {
    expect(
      parseGetProjectStorageResults(
        mockGetProjectStorageCountGraphQLResponse.data,
        defaultProvideValues.helpLinks,
      ),
    ).toMatchObject(projectData);
  });

  it('includes storage type with size of 0 in returned value', () => {
    const mockedResponse = mockGetProjectStorageCountGraphQLResponse.data;
    // ensuring a specific storage type item has size of 0
    mockedResponse.project.statistics.repositorySize = 0;

    const response = parseGetProjectStorageResults(mockedResponse, defaultProvideValues.helpLinks);

    expect(response.storage.storageTypes).toEqual(
      expect.arrayContaining([
        {
          storageType: expect.any(Object),
          value: 0,
        },
      ]),
    );
  });
});
