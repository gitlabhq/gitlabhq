import * as types from './mutation_types';
import { normalizeLicense, byLicenseNameComparator } from './utils';

export default {
  [types.SET_LICENSE_IN_MODAL](state, license) {
    Object.assign(state, {
      currentLicenseInModal: license,
    });
  },
  [types.RESET_LICENSE_IN_MODAL](state) {
    Object.assign(state, {
      currentLicenseInModal: null,
    });
  },
  [types.SET_API_SETTINGS](state, data) {
    Object.assign(state, data);
  },

  [types.RECEIVE_LOAD_MANAGED_LICENSES](state, licenses = []) {
    const managedLicenses = licenses.map(normalizeLicense).sort(byLicenseNameComparator);

    Object.assign(state, {
      managedLicenses,
      isLoadingManagedLicenses: false,
      loadManagedLicensesError: false,
    });
  },
  [types.RECEIVE_LOAD_MANAGED_LICENSES_ERROR](state, error) {
    Object.assign(state, {
      managedLicenses: [],
      isLoadingManagedLicenses: false,
      loadManagedLicensesError: error,
    });
  },
  [types.REQUEST_LOAD_MANAGED_LICENSES](state) {
    Object.assign(state, {
      isLoadingManagedLicenses: true,
    });
  },

  [types.RECEIVE_LOAD_LICENSE_REPORT](state, reports) {
    const { headReport, baseReport } = reports;

    Object.assign(state, {
      headReport,
      baseReport,
      isLoadingLicenseReport: false,
      loadLicenseReportError: false,
    });
  },
  [types.RECEIVE_LOAD_LICENSE_REPORT_ERROR](state, error) {
    Object.assign(state, {
      managedLicenses: [],
      isLoadingLicenseReport: false,
      loadLicenseReportError: error,
    });
  },
  [types.REQUEST_LOAD_LICENSE_REPORT](state) {
    Object.assign(state, {
      isLoadingLicenseReport: true,
    });
  },

  [types.RECEIVE_DELETE_LICENSE](state) {
    Object.assign(state, {
      isDeleting: false,
      currentLicenseInModal: null,
    });
  },
  [types.RECEIVE_DELETE_LICENSE_ERROR](state) {
    Object.assign(state, {
      isDeleting: false,
      currentLicenseInModal: null,
    });
  },
  [types.REQUEST_DELETE_LICENSE](state) {
    Object.assign(state, {
      isDeleting: true,
    });
  },
  [types.REQUEST_SET_LICENSE_APPROVAL](state) {
    Object.assign(state, {
      isSaving: true,
    });
  },
  [types.RECEIVE_SET_LICENSE_APPROVAL](state) {
    Object.assign(state, {
      isSaving: false,
      currentLicenseInModal: null,
    });
  },
  [types.RECEIVE_SET_LICENSE_APPROVAL_ERROR](state) {
    Object.assign(state, {
      isSaving: false,
      currentLicenseInModal: null,
    });
  },
};
