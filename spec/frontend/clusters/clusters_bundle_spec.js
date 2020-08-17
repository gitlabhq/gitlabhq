import MockAdapter from 'axios-mock-adapter';
import { loadHTMLFixture } from 'helpers/fixtures';
import { setTestTimeout } from 'helpers/timeout';
import Clusters from '~/clusters/clusters_bundle';
import { APPLICATION_STATUS, APPLICATIONS, RUNNER } from '~/clusters/constants';
import axios from '~/lib/utils/axios_utils';
import initProjectSelectDropdown from '~/project_select';

jest.mock('~/lib/utils/poll');
jest.mock('~/project_select');

const { INSTALLING, INSTALLABLE, INSTALLED, UNINSTALLING } = APPLICATION_STATUS;

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

  describe('checkForNewInstalls', () => {
    const INITIAL_APP_MAP = {
      helm: { status: null, title: 'Helm Tiller' },
      ingress: { status: null, title: 'Ingress' },
      runner: { status: null, title: 'GitLab Runner' },
    };

    it('does not show alert when things transition from initial null state to something', () => {
      cluster.checkForNewInstalls(INITIAL_APP_MAP, {
        ...INITIAL_APP_MAP,
        helm: { status: INSTALLABLE, title: 'Helm Tiller' },
      });

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).toBeNull();
    });

    it('shows an alert when something gets newly installed', () => {
      cluster.checkForNewInstalls(
        {
          ...INITIAL_APP_MAP,
          helm: { status: INSTALLING, title: 'Helm Tiller' },
        },
        {
          ...INITIAL_APP_MAP,
          helm: { status: INSTALLED, title: 'Helm Tiller' },
        },
      );

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual(
        'Helm Tiller was successfully installed on your Kubernetes cluster',
      );
    });

    it('shows an alert when multiple things gets newly installed', () => {
      cluster.checkForNewInstalls(
        {
          ...INITIAL_APP_MAP,
          helm: { status: INSTALLING, title: 'Helm Tiller' },
          ingress: { status: INSTALLABLE, title: 'Ingress' },
        },
        {
          ...INITIAL_APP_MAP,
          helm: { status: INSTALLED, title: 'Helm Tiller' },
          ingress: { status: INSTALLED, title: 'Ingress' },
        },
      );

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual(
        'Helm Tiller, Ingress was successfully installed on your Kubernetes cluster',
      );
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

  describe('installApplication', () => {
    it.each(APPLICATIONS)('tries to install %s', (applicationId, done) => {
      jest.spyOn(cluster.service, 'installApplication').mockResolvedValue();

      cluster.store.state.applications[applicationId].status = INSTALLABLE;

      const params = {};
      if (applicationId === 'knative') {
        params.hostname = 'test-example.com';
      }

      // eslint-disable-next-line promise/valid-params
      cluster
        .installApplication({ id: applicationId, params })
        .then(() => {
          expect(cluster.store.state.applications[applicationId].status).toEqual(INSTALLING);
          expect(cluster.store.state.applications[applicationId].requestReason).toEqual(null);
          expect(cluster.service.installApplication).toHaveBeenCalledWith(applicationId, params);
          done();
        })
        .catch();
    });

    it('sets error request status when the request fails', () => {
      jest
        .spyOn(cluster.service, 'installApplication')
        .mockRejectedValueOnce(new Error('STUBBED ERROR'));

      cluster.store.state.applications.helm.status = INSTALLABLE;

      const promise = cluster.installApplication({ id: 'helm' });

      return promise.then(() => {
        expect(cluster.store.state.applications.helm.status).toEqual(INSTALLABLE);
        expect(cluster.store.state.applications.helm.installFailed).toBe(true);

        expect(cluster.store.state.applications.helm.requestReason).toBeDefined();
      });
    });
  });

  describe('uninstallApplication', () => {
    it.each(APPLICATIONS)('tries to uninstall %s', applicationId => {
      jest.spyOn(cluster.service, 'uninstallApplication').mockResolvedValueOnce();

      cluster.store.state.applications[applicationId].status = INSTALLED;

      cluster.uninstallApplication({ id: applicationId });

      expect(cluster.store.state.applications[applicationId].status).toEqual(UNINSTALLING);
      expect(cluster.store.state.applications[applicationId].requestReason).toEqual(null);
      expect(cluster.service.uninstallApplication).toHaveBeenCalledWith(applicationId);
    });

    it('sets error request status when the uninstall request fails', () => {
      jest
        .spyOn(cluster.service, 'uninstallApplication')
        .mockRejectedValueOnce(new Error('STUBBED ERROR'));

      cluster.store.state.applications.helm.status = INSTALLED;

      const promise = cluster.uninstallApplication({ id: 'helm' });

      return promise.then(() => {
        expect(cluster.store.state.applications.helm.status).toEqual(INSTALLED);
        expect(cluster.store.state.applications.helm.uninstallFailed).toBe(true);
        expect(cluster.store.state.applications.helm.requestReason).toBeDefined();
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
      jest.spyOn(cluster, 'checkForNewInstalls').mockReturnThis();
      jest.spyOn(cluster, 'updateContainer').mockReturnThis();
      cluster.handleClusterStatusSuccess({ data: {} });
    });

    it('updates clusters store', () => {
      expect(cluster.store.updateStateFromServer).toHaveBeenCalled();
    });

    it('checks for new installable apps', () => {
      expect(cluster.checkForNewInstalls).toHaveBeenCalled();
    });

    it('updates message containers', () => {
      expect(cluster.updateContainer).toHaveBeenCalled();
    });
  });

  describe('updateApplication', () => {
    const params = { version: '1.0.0' };
    let storeUpdateApplication;
    let installApplication;

    beforeEach(() => {
      storeUpdateApplication = jest.spyOn(cluster.store, 'updateApplication');
      installApplication = jest.spyOn(cluster.service, 'installApplication');

      cluster.updateApplication({ id: RUNNER, params });
    });

    afterEach(() => {
      storeUpdateApplication.mockRestore();
      installApplication.mockRestore();
    });

    it('calls store updateApplication method', () => {
      expect(storeUpdateApplication).toHaveBeenCalledWith(RUNNER);
    });

    it('sends installApplication request', () => {
      expect(installApplication).toHaveBeenCalledWith(RUNNER, params);
    });
  });
});
