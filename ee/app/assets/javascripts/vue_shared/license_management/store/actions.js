import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export const setAPISettings = ({ commit }, data) => {
  commit(types.SET_API_SETTINGS, data);
};

export const setLicenseInModal = ({ commit }, license) => {
  commit(types.SET_LICENSE_IN_MODAL, license);
};
export const resetLicenseInModal = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};

export const requestDeleteLicense = ({ commit }) => {
  commit(types.REQUEST_DELETE_LICENSE);
};
export const receiveDeleteLicense = ({ commit, dispatch }) => {
  commit(types.RECEIVE_DELETE_LICENSE);
  dispatch('loadManagedLicenses');
};
export const receiveDeleteLicenseError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_LICENSE_ERROR, error);
};
export const deleteLicense = ({ dispatch, state }) => {
  const licenseId = state.currentLicenseInModal.id;
  dispatch('requestDeleteLicense');
  const endpoint = `${state.apiUrlManageLicenses}/${licenseId}`;
  return axios
    .delete(endpoint)
    .then(() => {
      dispatch('receiveDeleteLicense');
    })
    .catch(error => {
      dispatch('receiveDeleteLicenseError', error);
    });
};

export const requestLoadManagedLicenses = ({ commit }) => {
  commit(types.REQUEST_LOAD_MANAGED_LICENSES);
};
export const receiveLoadManagedLicenses = ({ commit }, licenses) => {
  commit(types.RECEIVE_LOAD_MANAGED_LICENSES, licenses);
};
export const receiveLoadManagedLicensesError = ({ commit }, error) => {
  commit(types.RECEIVE_LOAD_MANAGED_LICENSES_ERROR, error);
};
export const loadManagedLicenses = ({ dispatch, state }) => {
  dispatch('requestLoadManagedLicenses');

  const { apiUrlManageLicenses } = state;

  return axios
    .get(apiUrlManageLicenses)
    .then(({ data }) => {
      dispatch('receiveLoadManagedLicenses', data);
    })
    .catch(error => {
      dispatch('receiveLoadManagedLicensesError', error);
    });
};

export const requestLoadLicenseReport = ({ commit }) => {
  commit(types.REQUEST_LOAD_LICENSE_REPORT);
};
export const receiveLoadLicenseReport = ({ commit }, reports) => {
  commit(types.RECEIVE_LOAD_LICENSE_REPORT, reports);
};
export const receiveLoadLicenseReportError = ({ commit }, error) => {
  commit(types.RECEIVE_LOAD_LICENSE_REPORT_ERROR, error);
};
export const loadLicenseReport = ({ dispatch, state }) => {
  dispatch('requestLoadLicenseReport');

  const { headPath, basePath } = state;

  const promises = [axios.get(headPath).then(({ data }) => data)];

  if (basePath) {
    promises.push(
      axios
        .get(basePath)
        .then(({ data }) => data)
        .catch(e => {
          if (e.response.status === 404) {
            return {};
          }

          throw e;
        }),
    );
  }

  return Promise.all(promises)
    .then(([headReport, baseReport = {}]) => {
      dispatch('receiveLoadLicenseReport', { headReport, baseReport });
    })
    .catch(error => {
      dispatch('receiveLoadLicenseReportError', error);
    });
};

export const requestSetLicenseApproval = ({ commit }) => {
  commit(types.REQUEST_SET_LICENSE_APPROVAL);
};
export const receiveSetLicenseApproval = ({ commit, dispatch }) => {
  commit(types.RECEIVE_SET_LICENSE_APPROVAL);
  dispatch('loadManagedLicenses');
};
export const receiveSetLicenseApprovalError = ({ commit }, error) => {
  commit(types.RECEIVE_SET_LICENSE_APPROVAL_ERROR, error);
};
export const setLicenseApproval = ({ dispatch, state }, payload) => {
  const { apiUrlManageLicenses } = state;
  const { license, newStatus } = payload;
  const { id, name } = license;

  dispatch('requestSetLicenseApproval');

  let request;

  /*
   Licenses that have an ID, are already in the database.
   So we need to send PATCH instead of POST.
   */
  if (id) {
    request = axios.patch(`${apiUrlManageLicenses}/${id}`, { approval_status: newStatus });
  } else {
    request = axios.post(apiUrlManageLicenses, { approval_status: newStatus, name });
  }

  return request
    .then(() => {
      dispatch('receiveSetLicenseApproval');
    })
    .catch(error => {
      dispatch('receiveSetLicenseApprovalError', error);
    });
};
export const approveLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.APPROVED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.APPROVED });
  }
};

export const blacklistLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.BLACKLISTED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED });
  }
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
