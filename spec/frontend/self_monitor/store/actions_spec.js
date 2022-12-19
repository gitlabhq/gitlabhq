import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import statusCodes, { HTTP_STATUS_ACCEPTED } from '~/lib/utils/http_status';
import * as actions from '~/self_monitor/store/actions';
import * as types from '~/self_monitor/store/mutation_types';
import createState from '~/self_monitor/store/state';

describe('self-monitor actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  describe('setSelfMonitor', () => {
    it('commits the SET_ENABLED mutation', () => {
      return testAction(
        actions.setSelfMonitor,
        null,
        state,
        [{ type: types.SET_ENABLED, payload: null }],
        [],
      );
    });
  });

  describe('resetAlert', () => {
    it('commits the SET_ENABLED mutation', () => {
      return testAction(
        actions.resetAlert,
        null,
        state,
        [{ type: types.SET_SHOW_ALERT, payload: false }],
        [],
      );
    });
  });

  describe('requestCreateProject', () => {
    describe('success', () => {
      beforeEach(() => {
        state.createProjectEndpoint = '/create';
        state.createProjectStatusEndpoint = '/create_status';
        mock.onPost(state.createProjectEndpoint).reply(HTTP_STATUS_ACCEPTED, {
          job_id: '123',
        });
        mock.onGet(state.createProjectStatusEndpoint).reply(statusCodes.OK, {
          project_full_path: '/self-monitor-url',
        });
      });

      it('dispatches status request with job data', () => {
        return testAction(
          actions.requestCreateProject,
          null,
          state,
          [
            {
              type: types.SET_LOADING,
              payload: true,
            },
          ],
          [
            {
              type: 'requestCreateProjectStatus',
              payload: '123',
            },
          ],
        );
      });

      it('dispatches success with project path', () => {
        return testAction(
          actions.requestCreateProjectStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestCreateProjectSuccess',
              payload: { project_full_path: '/self-monitor-url' },
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        state.createProjectEndpoint = '/create';
        mock.onPost(state.createProjectEndpoint).reply(500);
      });

      it('dispatches error', () => {
        return testAction(
          actions.requestCreateProject,
          null,
          state,
          [
            {
              type: types.SET_LOADING,
              payload: true,
            },
          ],
          [
            {
              type: 'requestCreateProjectError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
        );
      });
    });

    describe('requestCreateProjectSuccess', () => {
      it('should commit the received data', () => {
        return testAction(
          actions.requestCreateProjectSuccess,
          { project_full_path: '/self-monitor-url' },
          state,
          [
            { type: types.SET_LOADING, payload: false },
            { type: types.SET_PROJECT_URL, payload: '/self-monitor-url' },
            {
              type: types.SET_ALERT_CONTENT,
              payload: {
                actionName: 'viewSelfMonitorProject',
                actionText: 'View project',
                message: 'Self-monitoring project successfully created.',
              },
            },
            { type: types.SET_SHOW_ALERT, payload: true },
            { type: types.SET_PROJECT_CREATED, payload: true },
          ],
          [
            {
              payload: true,
              type: 'setSelfMonitor',
            },
          ],
        );
      });
    });
  });

  describe('deleteSelfMonitorProject', () => {
    describe('success', () => {
      beforeEach(() => {
        state.deleteProjectEndpoint = '/delete';
        state.deleteProjectStatusEndpoint = '/delete-status';
        mock.onDelete(state.deleteProjectEndpoint).reply(HTTP_STATUS_ACCEPTED, {
          job_id: '456',
        });
        mock.onGet(state.deleteProjectStatusEndpoint).reply(statusCodes.OK, {
          status: 'success',
        });
      });

      it('dispatches status request with job data', () => {
        return testAction(
          actions.requestDeleteProject,
          null,
          state,
          [
            {
              type: types.SET_LOADING,
              payload: true,
            },
          ],
          [
            {
              type: 'requestDeleteProjectStatus',
              payload: '456',
            },
          ],
        );
      });

      it('dispatches success with status', () => {
        return testAction(
          actions.requestDeleteProjectStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestDeleteProjectSuccess',
              payload: { status: 'success' },
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        state.deleteProjectEndpoint = '/delete';
        mock.onDelete(state.deleteProjectEndpoint).reply(500);
      });

      it('dispatches error', () => {
        return testAction(
          actions.requestDeleteProject,
          null,
          state,
          [
            {
              type: types.SET_LOADING,
              payload: true,
            },
          ],
          [
            {
              type: 'requestDeleteProjectError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
        );
      });
    });

    describe('requestDeleteProjectSuccess', () => {
      it('should commit mutations to remove previously set data', () => {
        return testAction(
          actions.requestDeleteProjectSuccess,
          null,
          state,
          [
            { type: types.SET_PROJECT_URL, payload: '' },
            { type: types.SET_PROJECT_CREATED, payload: false },
            {
              type: types.SET_ALERT_CONTENT,
              payload: {
                actionName: 'createProject',
                actionText: 'Undo',
                message: 'Self-monitoring project successfully deleted.',
              },
            },
            { type: types.SET_SHOW_ALERT, payload: true },
            { type: types.SET_LOADING, payload: false },
          ],
          [],
        );
      });
    });
  });
});
