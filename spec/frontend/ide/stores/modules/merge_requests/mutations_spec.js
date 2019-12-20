import { TEST_HOST } from 'helpers/test_constants';
import state from '~/ide/stores/modules/merge_requests/state';
import mutations from '~/ide/stores/modules/merge_requests/mutations';
import * as types from '~/ide/stores/modules/merge_requests/mutation_types';
import { mergeRequests } from '../../../mock_data';

describe('IDE merge requests mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('REQUEST_MERGE_REQUESTS', () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_MERGE_REQUESTS](mockedState);

      expect(mockedState.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_MERGE_REQUESTS_ERROR', () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_MERGE_REQUESTS_ERROR](mockedState);

      expect(mockedState.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_MERGE_REQUESTS_SUCCESS', () => {
    it('sets merge requests', () => {
      gon.gitlab_url = TEST_HOST;
      mutations[types.RECEIVE_MERGE_REQUESTS_SUCCESS](mockedState, mergeRequests);

      expect(mockedState.mergeRequests).toEqual([
        {
          id: 1,
          iid: 1,
          title: 'Test merge request',
          projectId: 1,
          projectPathWithNamespace: 'namespace/project-path',
        },
      ]);
    });
  });

  describe('RESET_MERGE_REQUESTS', () => {
    it('clears merge request array', () => {
      mockedState.mergeRequests = ['test'];

      mutations[types.RESET_MERGE_REQUESTS](mockedState);

      expect(mockedState.mergeRequests).toEqual([]);
    });
  });
});
