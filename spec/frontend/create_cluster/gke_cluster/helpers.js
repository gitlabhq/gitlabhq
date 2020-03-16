import {
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from './mock_data';

const cloudbilling = {
  projects: {
    getBillingInfo: jest.fn(
      () =>
        new Promise(resolve => {
          resolve({
            result: { billingEnabled: true },
          });
        }),
    ),
  },
};

const cloudresourcemanager = {
  projects: {
    list: jest.fn(
      () =>
        new Promise(resolve => {
          resolve({
            result: { ...gapiProjectsResponseMock },
          });
        }),
    ),
  },
};

const compute = {
  zones: {
    list: jest.fn(
      () =>
        new Promise(resolve => {
          resolve({
            result: { ...gapiZonesResponseMock },
          });
        }),
    ),
  },
  machineTypes: {
    list: jest.fn(
      () =>
        new Promise(resolve => {
          resolve({
            result: { ...gapiMachineTypesResponseMock },
          });
        }),
    ),
  },
};

const gapi = {
  client: {
    cloudbilling,
    cloudresourcemanager,
    compute,
  },
};

export { gapi as default };
