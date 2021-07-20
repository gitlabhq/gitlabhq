import MockAdapter from 'axios-mock-adapter';
import { loadHTMLFixture } from 'helpers/fixtures';
import { setTestTimeout } from 'helpers/timeout';
import Clusters from '~/clusters/clusters_bundle';
import axios from '~/lib/utils/axios_utils';
import initProjectSelectDropdown from '~/project_select';

jest.mock('~/lib/utils/poll');
jest.mock('~/project_select');

describe('Clusters', () => {
  setTestTimeout(1000);

  let cluster;
  let mock;

  const mockGetClusterStatusRequest = () => {
    const { statusPath } = document.querySelector('.js-edit-cluster-form').dataset;

    mock = new MockAdapter(axios);

    mock.onGet(statusPath).reply(200);
  };

  beforeEach(() => {
    loadHTMLFixture('clusters/show_cluster.html');
  });

  beforeEach(() => {
    mockGetClusterStatusRequest();
  });

  beforeEach(() => {
    cluster = new Clusters();
  });

  afterEach(() => {
    cluster.destroy();
    mock.restore();
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
      expect(initProjectSelectDropdown).toHaveBeenCalled();
    });
  });

  describe('updateContainer', () => {
    const { location } = window;

    beforeEach(() => {
      delete window.location;
      window.location = {
        reload: jest.fn(),
        hash: location.hash,
      };
    });

    afterEach(() => {
      window.location = location;
    });

    describe('when creating cluster', () => {
      it('should show the creating container', () => {
        cluster.updateContainer(null, 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeFalsy();
        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('should continue to show `creating` banner with subsequent updates of the same status', () => {
        cluster.updateContainer(null, 'creating');
        cluster.updateContainer('creating', 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeFalsy();
        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });

    describe('when cluster is created', () => {
      it('should hide the "creating" banner and refresh the page', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        cluster.updateContainer(null, 'creating');
        cluster.updateContainer('creating', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
        expect(window.location.reload).toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).toHaveBeenCalledWith(true);
      });

      it('when the page is refreshed, it should show the "success" banner', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        jest.spyOn(cluster, 'isClusterNewlyCreated').mockReturnValue(true);

        cluster.updateContainer(null, 'created');
        cluster.updateContainer('created', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.successContainer.classList.contains('hidden')).toBeFalsy();
        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
        expect(window.location.reload).not.toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).toHaveBeenCalledWith(false);
      });

      it('should not show a banner when status is already `created`', () => {
        jest.spyOn(cluster, 'setClusterNewlyCreated');
        jest.spyOn(cluster, 'isClusterNewlyCreated').mockReturnValue(false);

        cluster.updateContainer(null, 'created');
        cluster.updateContainer('created', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();
        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
        expect(window.location.reload).not.toHaveBeenCalled();
        expect(cluster.setClusterNewlyCreated).not.toHaveBeenCalled();
      });
    });

    describe('when cluster has error', () => {
      it('should show the error container', () => {
        cluster.updateContainer(null, 'errored', 'this is an error');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeFalsy();

        expect(cluster.errorReasonContainer.textContent).toContain('this is an error');
      });

      it('should show `error` banner when previously `creating`', () => {
        cluster.updateContainer('creating', 'errored');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeFalsy();
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
