import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/create_cluster/gke_cluster/store/actions';
import * as types from '~/create_cluster/gke_cluster/store/mutation_types';
import createState from '~/create_cluster/gke_cluster/store/state';
import gapi from '../helpers';
import {
  selectedProjectMock,
  selectedZoneMock,
  selectedMachineTypeMock,
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from '../mock_data';

describe('GCP Cluster Dropdown Store Actions', () => {
  describe('setProject', () => {
    it('should set project', (done) => {
      testAction(
        actions.setProject,
        selectedProjectMock,
        { selectedProject: {} },
        [{ type: 'SET_PROJECT', payload: selectedProjectMock }],
        [],
        done,
      );
    });
  });

  describe('setZone', () => {
    it('should set zone', (done) => {
      testAction(
        actions.setZone,
        selectedZoneMock,
        { selectedZone: '' },
        [{ type: 'SET_ZONE', payload: selectedZoneMock }],
        [],
        done,
      );
    });
  });

  describe('setMachineType', () => {
    it('should set machine type', (done) => {
      testAction(
        actions.setMachineType,
        selectedMachineTypeMock,
        { selectedMachineType: '' },
        [{ type: 'SET_MACHINE_TYPE', payload: selectedMachineTypeMock }],
        [],
        done,
      );
    });
  });

  describe('setIsValidatingProjectBilling', () => {
    it('should set machine type', (done) => {
      testAction(
        actions.setIsValidatingProjectBilling,
        true,
        { isValidatingProjectBilling: null },
        [{ type: 'SET_IS_VALIDATING_PROJECT_BILLING', payload: true }],
        [],
        done,
      );
    });
  });

  describe('async fetch methods', () => {
    let originalGapi;

    beforeAll(() => {
      originalGapi = window.gapi;
      window.gapi = gapi;
      window.gapiPromise = Promise.resolve(gapi);
    });

    afterAll(() => {
      window.gapi = originalGapi;
      delete window.gapiPromise;
    });

    describe('fetchProjects', () => {
      it('fetches projects from Google API', () => {
        const state = createState();

        return testAction(
          actions.fetchProjects,
          null,
          state,
          [{ type: types.SET_PROJECTS, payload: gapiProjectsResponseMock.projects }],
          [],
        );
      });
    });

    describe('validateProjectBilling', () => {
      it('checks project billing status from Google API', (done) => {
        testAction(
          actions.validateProjectBilling,
          true,
          {
            selectedProject: selectedProjectMock,
            selectedZone: '',
            selectedMachineType: '',
            projectHasBillingEnabled: null,
          },
          [
            { type: 'SET_ZONE', payload: '' },
            { type: 'SET_MACHINE_TYPE', payload: '' },
            { type: 'SET_PROJECT_BILLING_STATUS', payload: true },
          ],
          [{ type: 'setIsValidatingProjectBilling', payload: false }],
          done,
        );
      });
    });

    describe('fetchZones', () => {
      it('fetches zones from Google API', () => {
        const state = createState();

        return testAction(
          actions.fetchZones,
          null,
          state,
          [{ type: types.SET_ZONES, payload: gapiZonesResponseMock.items }],
          [],
        );
      });
    });

    describe('fetchMachineTypes', () => {
      it('fetches machine types from Google API', () => {
        const state = createState();

        return testAction(
          actions.fetchMachineTypes,
          null,
          state,
          [{ type: types.SET_MACHINE_TYPES, payload: gapiMachineTypesResponseMock.items }],
          [],
        );
      });
    });
  });
});
