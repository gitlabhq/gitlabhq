import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import { useErrorTrackingSettings } from '~/error_tracking_settings/store';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import {
  initialEmptyState,
  initialPopulatedState,
  normalizedProject,
  projectList,
  projectWithHtmlTemplate,
  sampleBackendProject,
  staleProject,
} from '../mock';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('error_tracking_settings store', () => {
  let store;
  let axiosMock;

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
    refreshCurrentPage.mockClear();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useErrorTrackingSettings();
  });

  describe('getters', () => {
    describe('hasProjects', () => {
      it('reflects when no projects exist', () => {
        expect(store.hasProjects).toBe(false);
      });

      it('reflects when projects exist', () => {
        store.projects = projectList;

        expect(store.hasProjects).toBe(true);
      });
    });

    describe('isProjectInvalid', () => {
      it('is false when a project is valid', () => {
        store.projects = projectList;
        [store.selectedProject] = projectList;

        expect(store.isProjectInvalid).toBe(false);
      });

      it('is true when a project is invalid', () => {
        store.projects = projectList;
        store.selectedProject = staleProject;

        expect(store.isProjectInvalid).toBe(true);
      });
    });

    describe('dropdownLabel', () => {
      it('displays correctly when there are no projects available', () => {
        expect(store.dropdownLabel).toBe('No projects available');
      });

      it('displays correctly when a project is selected', () => {
        [store.selectedProject] = projectList;

        expect(store.dropdownLabel).toBe('organizationName | slug');
      });

      it('displays correctly when no project is selected', () => {
        store.projects = projectList;

        expect(store.dropdownLabel).toBe('Select project');
      });
    });

    describe('invalidProjectLabel', () => {
      it('displays an error containing the project name', () => {
        [store.selectedProject] = projectList;

        expect(store.invalidProjectLabel).toBe(
          'Project "name" is no longer available. Select another project to continue.',
        );
      });

      it('properly escapes the label text', () => {
        store.selectedProject = projectWithHtmlTemplate;

        expect(store.invalidProjectLabel).toBe(
          'Project "&lt;strong&gt;bold&lt;/strong&gt;" is no longer available. Select another project to continue.',
        );
      });
    });

    describe('projectSelectionLabel', () => {
      it('shows the correct message when the token is empty', () => {
        expect(store.projectSelectionLabel).toBe(
          'To enable project selection, enter a valid Auth Token.',
        );
      });

      it('shows the correct message when token exists', () => {
        store.token = 'test-token';

        expect(store.projectSelectionLabel).toBe(
          'Click Connect to reestablish the connection to Sentry and activate the dropdown.',
        );
      });
    });
  });

  describe('setInitialState', () => {
    it('creates an empty initial state correctly', () => {
      store.setInitialState({ ...initialEmptyState });

      expect(store.apiHost).toBe('');
      expect(store.enabled).toBe(false);
      expect(store.integrated).toBe(false);
      expect(store.selectedProject).toBeNull();
      expect(store.token).toBe('');
      expect(store.listProjectsEndpoint).toBe(TEST_HOST);
      expect(store.operationsSettingsEndpoint).toBe(TEST_HOST);
    });

    it('populates the initial state correctly', () => {
      store.setInitialState({ ...initialPopulatedState });

      expect(store.apiHost).toBe('apiHost');
      expect(store.enabled).toBe(true);
      expect(store.integrated).toBe(true);
      expect(store.selectedProject).toEqual(projectList[0]);
      expect(store.token).toBe('token');
      expect(store.listProjectsEndpoint).toBe(TEST_HOST);
      expect(store.operationsSettingsEndpoint).toBe(TEST_HOST);
    });
  });

  describe('fetchProjects', () => {
    beforeEach(() => {
      store.listProjectsEndpoint = TEST_HOST;
    });

    it('requests and transforms the project list', async () => {
      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, { projects: [sampleBackendProject] });

      await store.fetchProjects();

      expect(store.projects).toEqual([normalizedProject]);
      expect(store.connectSuccessful).toBe(true);
      expect(store.connectError).toBe(false);
      expect(store.isLoadingProjects).toBe(false);
    });

    it('strips out unnecessary project properties', async () => {
      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, {
        projects: [{ ...sampleBackendProject, extra_property: 'extra' }],
      });

      await store.fetchProjects();

      expect(store.projects).toEqual([normalizedProject]);
    });

    it('handles a server error', async () => {
      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_BAD_REQUEST);

      await store.fetchProjects();

      expect(store.projects).toEqual([]);
      expect(store.connectSuccessful).toBe(false);
      expect(store.connectError).toBe(true);
      expect(store.isLoadingProjects).toBe(false);
    });

    it('sets isLoadingProjects=true mid-flight', () => {
      axiosMock.onGet(TEST_HOST).reply(() => new Promise(() => {}));

      store.fetchProjects();

      expect(store.isLoadingProjects).toBe(true);
    });

    it('resets connect flags when starting a new request', () => {
      axiosMock.onGet(TEST_HOST).reply(() => new Promise(() => {}));
      store.connectSuccessful = true;
      store.connectError = true;

      store.fetchProjects();

      expect(store.connectSuccessful).toBe(false);
      expect(store.connectError).toBe(false);
    });
  });

  describe('updateSettings', () => {
    beforeEach(() => {
      store.operationsSettingsEndpoint = TEST_HOST;
    });

    it('saves the page and refreshes on success', async () => {
      axiosMock.onPatch(TEST_HOST).reply(HTTP_STATUS_OK);

      await store.updateSettings();

      expect(axiosMock.history.patch).toHaveLength(1);
      expect(refreshCurrentPage).toHaveBeenCalled();
    });

    it('handles a server error and resets settingsLoading', async () => {
      axiosMock.onPatch(TEST_HOST).reply(HTTP_STATUS_BAD_REQUEST);

      await store.updateSettings();

      expect(axiosMock.history.patch).toHaveLength(1);
      expect(store.settingsLoading).toBe(false);
    });

    it('sets settingsLoading=true mid-flight', () => {
      axiosMock.onPatch(TEST_HOST).reply(() => new Promise(() => {}));

      store.updateSettings();

      expect(store.settingsLoading).toBe(true);
    });
  });

  describe('generic setters', () => {
    it.each([true, false])('sets `integrated` to `%s`', (payload) => {
      store.updateIntegrated(payload);

      expect(store.integrated).toBe(payload);
    });

    it('resets the connect success flag when updating the api host', () => {
      store.connectSuccessful = true;
      store.connectError = true;

      store.updateApiHost('new-host');

      expect(store.apiHost).toBe('new-host');
      expect(store.connectSuccessful).toBe(false);
      expect(store.connectError).toBe(false);
    });

    it('resets the connect success flag when updating the token', () => {
      store.connectSuccessful = true;
      store.connectError = true;

      store.updateToken('new-token');

      expect(store.token).toBe('new-token');
      expect(store.connectSuccessful).toBe(false);
      expect(store.connectError).toBe(false);
    });
  });
});
