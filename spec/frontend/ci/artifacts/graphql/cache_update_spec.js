import getJobArtifactsQuery from '~/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql';
import { removeArtifactFromStore } from '~/ci/artifacts/graphql/cache_update';

describe('Artifact table cache updates', () => {
  let store;

  const cacheMock = {
    project: {
      jobs: {
        nodes: [
          { artifacts: { nodes: [{ id: 'foo' }] } },
          { artifacts: { nodes: [{ id: 'bar' }] } },
        ],
      },
    },
  };

  const query = getJobArtifactsQuery;
  const variables = { fullPath: 'path/to/project' };

  beforeEach(() => {
    store = {
      readQuery: jest.fn().mockReturnValue(cacheMock),
      writeQuery: jest.fn(),
    };
  });

  describe('removeArtifactFromStore', () => {
    it('calls readQuery', () => {
      removeArtifactFromStore(store, 'foo', query, variables);
      expect(store.readQuery).toHaveBeenCalledWith({ query, variables });
    });

    it('writes the correct result in the cache', () => {
      removeArtifactFromStore(store, 'foo', query, variables);
      expect(store.writeQuery).toHaveBeenCalledWith({
        query,
        variables,
        data: {
          project: {
            jobs: {
              nodes: [{ artifacts: { nodes: [] } }, { artifacts: { nodes: [{ id: 'bar' }] } }],
            },
          },
        },
      });
    });

    it('does not remove an unknown artifact', () => {
      removeArtifactFromStore(store, 'baz', query, variables);
      expect(store.writeQuery).toHaveBeenCalledWith({
        query,
        variables,
        data: {
          project: {
            jobs: {
              nodes: [
                { artifacts: { nodes: [{ id: 'foo' }] } },
                { artifacts: { nodes: [{ id: 'bar' }] } },
              ],
            },
          },
        },
      });
    });
  });
});
