import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import { candidate } from './graphql_mock_data';

describe('~/ml/model_registry/utils', () => {
  describe('convertCandidateFromGraphql', () => {
    it('converts from graphql response', () => {
      const converted = convertCandidateFromGraphql(candidate);
      const expectedResponse = {
        info: {
          iid: 1,
          eid: 'e9a71521-45c6-4b0a-b0c3-21f0b4528a5c',
          status: 'running',
          experimentName: '',
          pathToExperiment: '',
          pathToArtifact: '/root/test-project/-/packages/1',
          path: '/root/test-project/-/ml/candidates/1',
          ciJob: {
            mergeRequest: {
              iid: 1,
              path: 'path/to/mr',
              title: 'Merge Request 1',
            },
            name: 'build:linux',
            path: '/gitlab-org/gitlab-test/-/jobs/1',
            user: {
              avatar: 'path/to/avatar',
              name: 'User 1',
              path: 'path/to/user/1',
              username: 'user1',
            },
          },
        },
        metrics: [
          {
            id: 'gid://gitlab/Ml::CandidateMetric/1',
            name: 'metric1',
            value: 0.3,
            step: 0,
          },
        ],
        params: [
          {
            id: 'gid://gitlab/Ml::CandidateParam/1',
            name: 'param1',
            value: 'value1',
          },
        ],
        metadata: [
          {
            id: 'gid://gitlab/Ml::CandidateMetadata/1',
            name: 'metadata1',
            value: 'metadataValue1',
          },
        ],
      };

      expect(converted).toEqual(expectedResponse);
    });
  });
});
