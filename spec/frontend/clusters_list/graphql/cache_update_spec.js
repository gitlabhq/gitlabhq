import {
  hasErrors,
  addAgentConfigToStore,
  removeAgentFromStore,
} from '~/clusters_list/graphql/cache_update';
import getClusterAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';

describe('Agent cache updates', () => {
  describe('hasErrors', () => {
    it('returns the length of errors array when it has items', () => {
      expect(hasErrors({ errors: ['error1', 'error2'] })).toBe(2);
    });

    it('returns 0 when errors array is empty', () => {
      expect(hasErrors({ errors: [] })).toBe(0);
    });

    it('returns 0 when errors is undefined', () => {
      expect(hasErrors({})).toBe(0);
    });
  });

  describe('addAgentConfigToStore', () => {
    let store;
    const query = getClusterAgentsQuery;
    const variables = { fullPath: 'path/to/project' };

    const cacheMock = {
      project: {
        clusterAgents: {
          nodes: [{ id: 'agent1' }, { id: 'agent2' }],
          count: 2,
        },
      },
    };

    const clusterAgent = { id: 'agent3' };

    beforeEach(() => {
      store = {
        readQuery: jest.fn().mockReturnValue(cacheMock),
        writeQuery: jest.fn(),
      };
    });

    it('calls readQuery with correct parameters', () => {
      addAgentConfigToStore(store, {}, clusterAgent, query, variables);
      expect(store.readQuery).toHaveBeenCalledWith({ query, variables });
    });

    it('adds the new agent to the cache and updates count', () => {
      addAgentConfigToStore(store, {}, clusterAgent, query, variables);

      expect(store.writeQuery).toHaveBeenCalledWith({
        query,
        variables,
        data: {
          project: {
            clusterAgents: {
              nodes: [{ id: 'agent1' }, { id: 'agent2' }, { id: 'agent3' }],
              count: 3,
            },
          },
        },
      });
    });

    it('does not update the store when there are errors', () => {
      addAgentConfigToStore(store, { errors: ['error'] }, clusterAgent, query, variables);

      expect(store.readQuery).not.toHaveBeenCalled();
      expect(store.writeQuery).not.toHaveBeenCalled();
    });
  });

  describe('removeAgentFromStore', () => {
    let store;
    const query = getClusterAgentsQuery;

    describe.each`
      fullPath             | isGroup
      ${'path/to/project'} | ${false}
      ${'path/to/group'}   | ${true}
    `('for $fullPath', ({ fullPath, isGroup }) => {
      const namespace = isGroup ? 'group' : 'project';
      const variables = { fullPath, isGroup };

      const cacheMock = {
        [namespace]: {
          clusterAgents: {
            nodes: [{ id: 'agent1' }, { id: 'agent2' }, { id: 'agent3' }],
            count: 3,
          },
        },
      };

      beforeEach(() => {
        store = {
          readQuery: jest.fn().mockReturnValue(cacheMock),
          writeQuery: jest.fn(),
        };
      });

      it('calls readQuery with correct parameters', () => {
        removeAgentFromStore(store, { id: 'agent2' }, query, variables);
        expect(store.readQuery).toHaveBeenCalledWith({ query, variables });
      });

      it('removes the agent from project cache and updates count', () => {
        removeAgentFromStore(store, { id: 'agent2' }, query, variables);

        expect(store.writeQuery).toHaveBeenCalledWith({
          query,
          variables,
          data: {
            [namespace]: {
              clusterAgents: {
                nodes: [{ id: 'agent1' }, { id: 'agent3' }],
                count: 2,
              },
            },
          },
        });
      });

      it('does not update the store when there are errors', () => {
        removeAgentFromStore(store, { id: 'agent2', errors: ['error'] }, query, variables);

        expect(store.readQuery).not.toHaveBeenCalled();
        expect(store.writeQuery).not.toHaveBeenCalled();
      });
    });
  });
});
