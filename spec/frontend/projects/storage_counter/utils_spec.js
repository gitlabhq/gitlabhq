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
});
