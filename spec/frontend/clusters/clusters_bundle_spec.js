import MockAdapter from 'axios-mock-adapter';
import htmlShowCluster from 'test_fixtures/clusters/show_cluster.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import Clusters from '~/clusters/clusters_bundle';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';

jest.mock('~/lib/utils/poll');
jest.mock('~/vue_shared/components/entity_select/init_project_selects');

useMockLocationHelper();

describe('Clusters', () => {
  let cluster;
  let mock;

  const mockGetClusterStatusRequest = () => {
    const { statusPath } = document.querySelector('.js-edit-cluster-form').dataset;

    mock = new MockAdapter(axios);

    mock.onGet(statusPath).reply(HTTP_STATUS_OK);
  };

  beforeEach(() => {
    setHTMLFixture(htmlShowCluster);

    mockGetClusterStatusRequest();

    cluster = new Clusters();
  });

  afterEach(() => {
    cluster.destroy();
    mock.restore();

    resetHTMLFixture();
  });

  describe('class constructor', () => {
    beforeEach(() => {
      jest.spyOn(Clusters.prototype, 'initPolling');
      cluster = new Clusters();
    });

    it('should call initPolling on construct', () => {
      expect(cluster.initPolling).toHaveBeenCalled();
    });

    it('should call initProjectSelectDropdown on construct', () => {
      expect(initProjectSelects).toHaveBeenCalled();
    });
  });

  describe('updateContainer', () => {
    describe('when creating cluster', () => {
      it('should show the creating container', () => {
        cluster.updateContainer(null, 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(false);
        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.errorContainer.classList.contains('hidden')).toBe(true);
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('should continue to show `creating` banner with subsequent updates of the same status', () => {
        cluster.updateContainer(null, 'creating');
        cluster.updateContainer('creating', 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(false);
        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.errorContainer.classList.contains('hidden')).toBe(true);
        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });

    describe('when cluster is created', () => {
      it('should hide the "creating" banner and refresh the page', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        cluster.updateContainer(null, 'creating');
        cluster.updateContainer('creating', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.errorContainer.classList.contains('hidden')).toBe(true);
        expect(window.location.reload).toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).toHaveBeenCalledWith(true);
      });

      it('when the page is refreshed, it should show the "success" banner', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        jest.spyOn(cluster, 'isClusterNewlyCreated').mockReturnValue(true);

        cluster.updateContainer(null, 'created');
        cluster.updateContainer('created', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.successContainer.classList.contains('hidden')).toBe(false);
        expect(cluster.errorContainer.classList.contains('hidden')).toBe(true);
        expect(window.location.reload).not.toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).toHaveBeenCalledWith(false);
      });

      it('should not show a banner when status is already `created`', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        jest.spyOn(cluster, 'isClusterNewlyCreated').mockReturnValue(false);

        cluster.updateContainer(null, 'created');
        cluster.updateContainer('created', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);
        expect(cluster.errorContainer.classList.contains('hidden')).toBe(true);
        expect(window.location.reload).not.toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).not.toHaveBeenCalled();
      });
    });

    describe('when cluster has error', () => {
      it('should show the error container', () => {
        cluster.updateContainer(null, 'errored', 'this is an error');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(true);

        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);

        expect(cluster.errorContainer.classList.contains('hidden')).toBe(false);

        expect(cluster.errorReasonContainer.textContent).toContain('this is an error');
      });

      it('should show `error` banner when previously `creating`', () => {
        cluster.updateContainer('creating', 'errored');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBe(true);

        expect(cluster.successContainer.classList.contains('hidden')).toBe(true);

        expect(cluster.errorContainer.classList.contains('hidden')).toBe(false);
      });
    });

    describe('when cluster is unreachable', () => {
      it('should show the unreachable warning container', () => {
        cluster.updateContainer(null, 'unreachable');

        expect(cluster.unreachableContainer.classList.contains('hidden')).toBe(false);
      });
    });

    describe('when cluster has an authentication failure', () => {
      it('should show the authentication failure warning container', () => {
        cluster.updateContainer(null, 'authentication_failure');

        expect(cluster.authenticationFailureContainer.classList.contains('hidden')).toBe(false);
      });
    });
  });

  describe('fetch cluster environments success', () => {
    beforeEach(() => {
      jest.spyOn(cluster.store, 'toggleFetchEnvironments').mockReturnThis();
      jest.spyOn(cluster.store, 'updateEnvironments').mockReturnThis();

      cluster.handleClusterEnvironmentsSuccess({ data: {} });
    });

    it('toggles the cluster environments loading icon', () => {
      expect(cluster.store.toggleFetchEnvironments).toHaveBeenCalled();
    });

    it('updates the store when cluster environments is retrieved', () => {
      expect(cluster.store.updateEnvironments).toHaveBeenCalled();
    });
  });

  describe('handleClusterStatusSuccess', () => {
    beforeEach(() => {
      jest.spyOn(cluster.store, 'updateStateFromServer').mockReturnThis();
      jest.spyOn(cluster, 'updateContainer').mockReturnThis();
      cluster.handleClusterStatusSuccess({ data: {} });
    });

    it('updates clusters store', () => {
      expect(cluster.store.updateStateFromServer).toHaveBeenCalled();
    });

    it('updates message containers', () => {
      expect(cluster.updateContainer).toHaveBeenCalled();
    });
  });
});
