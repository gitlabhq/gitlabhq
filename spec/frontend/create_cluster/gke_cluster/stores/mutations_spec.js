import createState from '~/create_cluster/gke_cluster/store/state';
import * as types from '~/create_cluster/gke_cluster/store/mutation_types';
import mutations from '~/create_cluster/gke_cluster/store/mutations';
import {
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from '../mock_data';

describe('GCP Cluster Dropdown Store Mutations', () => {
  describe.each`
    mutation                                   | stateProperty                   | mockData
    ${types.SET_PROJECTS}                      | ${'projects'}                   | ${gapiProjectsResponseMock.projects}
    ${types.SET_ZONES}                         | ${'zones'}                      | ${gapiZonesResponseMock.items}
    ${types.SET_MACHINE_TYPES}                 | ${'machineTypes'}               | ${gapiMachineTypesResponseMock.items}
    ${types.SET_MACHINE_TYPE}                  | ${'selectedMachineType'}        | ${gapiMachineTypesResponseMock.items[0].name}
    ${types.SET_ZONE}                          | ${'selectedZone'}               | ${gapiZonesResponseMock.items[0].name}
    ${types.SET_PROJECT}                       | ${'selectedProject'}            | ${gapiProjectsResponseMock.projects[0]}
    ${types.SET_PROJECT_BILLING_STATUS}        | ${'projectHasBillingEnabled'}   | ${true}
    ${types.SET_IS_VALIDATING_PROJECT_BILLING} | ${'isValidatingProjectBilling'} | ${true}
  `('$mutation', ({ mutation, stateProperty, mockData }) => {
    it(`should set the mutation payload to the ${stateProperty} state property`, () => {
      const state = createState();

      expect(state[stateProperty]).not.toBe(mockData);

      mutations[mutation](state, mockData);

      expect(state[stateProperty]).toBe(mockData);
    });
  });
});
