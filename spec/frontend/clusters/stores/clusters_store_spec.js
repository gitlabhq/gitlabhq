import ClustersStore from '~/clusters/stores/clusters_store';
import { CLUSTERS_MOCK_DATA } from '../services/mock_data';

describe('Clusters Store', () => {
  let store;

  beforeEach(() => {
    store = new ClustersStore();
  });

  describe('updateStatus', () => {
    it('should store new status', () => {
      expect(store.state.status).toEqual(null);

      const newStatus = 'errored';
      store.updateStatus(newStatus);

      expect(store.state.status).toEqual(newStatus);
    });
  });

  describe('updateStatusReason', () => {
    it('should store new reason', () => {
      expect(store.state.statusReason).toEqual(null);

      const newReason = 'Something went wrong!';
      store.updateStatusReason(newReason);

      expect(store.state.statusReason).toEqual(newReason);
    });
  });

  describe('updateStateFromServer', () => {
    it('should store new polling data from server', () => {
      const mockResponseData =
        CLUSTERS_MOCK_DATA.GET['/gitlab-org/gitlab-shell/clusters/1/status.json'].data;
      store.updateStateFromServer(mockResponseData);

      expect(store.state).toEqual({
        helpPath: null,
        environmentsHelpPath: null,
        clustersHelpPath: null,
        deployBoardsHelpPath: null,
        status: mockResponseData.status,
        statusReason: mockResponseData.status_reason,
        providerType: null,
        rbac: false,
        environments: [],
        fetchingEnvironments: false,
      });
    });
  });
});
