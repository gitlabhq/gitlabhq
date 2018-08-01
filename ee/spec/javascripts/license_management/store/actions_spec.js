import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/vue_shared/license_management/store/actions';
import * as mutationTypes from 'ee/vue_shared/license_management/store/mutation_types';
import createState from 'ee/vue_shared/license_management/store/state';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'spec/helpers/vuex_action_helper';
import {
  approvedLicense,
  blacklistedLicense,
  licenseHeadIssues,
  licenseBaseIssues,
} from 'ee_spec/license_management/mock_data';

describe('License store actions', () => {
  const apiUrlManageLicenses = `${TEST_HOST}/licenses/management`;
  const headPath = `${TEST_HOST}/licenses/head`;
  const basePath = `${TEST_HOST}/licenses/base`;

  let axiosMock;
  let licenseId;
  let state;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = {
      ...createState(),
      apiUrlManageLicenses,
      headPath,
      basePath,
      currentLicenseInModal: approvedLicense,
    };
    licenseId = approvedLicense.id;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('setAPISettings', () => {
    it('commits SET_API_SETTINGS', done => {
      const payload = { headPath, apiUrlManageLicenses };
      testAction(
        actions.setAPISettings,
        payload,
        state,
        [{ type: mutationTypes.SET_API_SETTINGS, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setLicenseInModal', () => {
    it('commits SET_LICENSE_IN_MODAL with license', done => {
      testAction(
        actions.setLicenseInModal,
        approvedLicense,
        state,
        [{ type: mutationTypes.SET_LICENSE_IN_MODAL, payload: approvedLicense }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('resetLicenseInModal', () => {
    it('commits RESET_LICENSE_IN_MODAL', done => {
      testAction(
        actions.resetLicenseInModal,
        null,
        state,
        [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestDeleteLicense', () => {
    it('commits REQUEST_DELETE_LICENSE', done => {
      testAction(
        actions.requestDeleteLicense,
        null,
        state,
        [{ type: mutationTypes.REQUEST_DELETE_LICENSE }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveDeleteLicense', () => {
    it('commits RECEIVE_DELETE_LICENSE and dispatches loadManagedLicenses', done => {
      testAction(
        actions.receiveDeleteLicense,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_LICENSE }],
        [{ type: 'loadManagedLicenses' }],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveDeleteLicenseError', () => {
    it('commits RECEIVE_DELETE_LICENSE_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveDeleteLicenseError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_LICENSE_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deleteLicense', () => {
    let endpointMock;
    let deleteUrl;

    beforeEach(() => {
      deleteUrl = `${apiUrlManageLicenses}/${licenseId}`;
      endpointMock = axiosMock.onDelete(deleteUrl);
    });

    it('dispatches requestDeleteLicense and receiveDeleteLicense for successful response', done => {
      endpointMock.replyOnce(req => {
        expect(req.url).toBe(deleteUrl);
        return [200, ''];
      });

      testAction(
        actions.deleteLicense,
        null,
        state,
        [],
        [{ type: 'requestDeleteLicense' }, { type: 'receiveDeleteLicense' }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestDeleteLicense and receiveDeleteLicenseError for error response', done => {
      endpointMock.replyOnce(req => {
        expect(req.url).toBe(deleteUrl);
        return [500, ''];
      });

      testAction(
        actions.deleteLicense,
        null,
        state,
        [],
        [
          { type: 'requestDeleteLicense' },
          { type: 'receiveDeleteLicenseError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestSetLicenseApproval', () => {
    it('commits REQUEST_SET_LICENSE_APPROVAL', done => {
      testAction(
        actions.requestSetLicenseApproval,
        null,
        state,
        [{ type: mutationTypes.REQUEST_SET_LICENSE_APPROVAL }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveSetLicenseApproval', () => {
    it('commits RECEIVE_SET_LICENSE_APPROVAL and dispatches loadManagedLicenses', done => {
      testAction(
        actions.receiveSetLicenseApproval,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_SET_LICENSE_APPROVAL }],
        [{ type: 'loadManagedLicenses' }],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveSetLicenseApprovalError', () => {
    it('commits RECEIVE_SET_LICENSE_APPROVAL_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveSetLicenseApprovalError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_SET_LICENSE_APPROVAL_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setLicenseApproval', () => {
    const newStatus = 'FAKE_STATUS';

    describe('uses POST endpoint for existing licenses;', function() {
      let putEndpointMock;
      let newLicense;

      beforeEach(() => {
        newLicense = { name: 'FOO LICENSE' };
        putEndpointMock = axiosMock.onPost(apiUrlManageLicenses);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApproval for successful response', done => {
        putEndpointMock.replyOnce(req => {
          const { approval_status, name } = JSON.parse(req.data);
          expect(req.url).toBe(apiUrlManageLicenses);
          expect(approval_status).toBe(newStatus);
          expect(name).toBe(name);
          return [200, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: newLicense, newStatus },
          state,
          [],
          [{ type: 'requestSetLicenseApproval' }, { type: 'receiveSetLicenseApproval' }],
        )
          .then(done)
          .catch(done.fail);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApprovalError for error response', done => {
        putEndpointMock.replyOnce(req => {
          expect(req.url).toBe(apiUrlManageLicenses);
          return [500, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: newLicense, newStatus },
          state,
          [],
          [
            { type: 'requestSetLicenseApproval' },
            { type: 'receiveSetLicenseApprovalError', payload: jasmine.any(Error) },
          ],
        )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('uses PATCH endpoint for existing licenses;', function() {
      let patchEndpointMock;
      let licenseUrl;

      beforeEach(() => {
        licenseUrl = `${apiUrlManageLicenses}/${licenseId}`;
        patchEndpointMock = axiosMock.onPatch(licenseUrl);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApproval for successful response', done => {
        patchEndpointMock.replyOnce(req => {
          expect(req.url).toBe(licenseUrl);
          const { approval_status, name } = JSON.parse(req.data);
          expect(approval_status).toBe(newStatus);
          expect(name).toBeUndefined();
          return [200, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: approvedLicense, newStatus },
          state,
          [],
          [{ type: 'requestSetLicenseApproval' }, { type: 'receiveSetLicenseApproval' }],
        )
          .then(done)
          .catch(done.fail);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApprovalError for error response', done => {
        patchEndpointMock.replyOnce(req => {
          expect(req.url).toBe(licenseUrl);
          return [500, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: approvedLicense, newStatus },
          state,
          [],
          [
            { type: 'requestSetLicenseApproval' },
            { type: 'receiveSetLicenseApprovalError', payload: jasmine.any(Error) },
          ],
        )
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('approveLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.APPROVED;

    it('dispatches setLicenseApproval for un-approved licenses', done => {
      const license = { name: 'FOO' };

      testAction(
        actions.approveLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches setLicenseApproval for blacklisted licenses', done => {
      const license = blacklistedLicense;

      testAction(
        actions.approveLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('does not dispatch setLicenseApproval for approved licenses', done => {
      testAction(actions.approveLicense, approvedLicense, state, [], [])
        .then(done)
        .catch(done.fail);
    });
  });

  describe('blacklistLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.BLACKLISTED;

    it('dispatches setLicenseApproval for un-approved licenses', done => {
      const license = { name: 'FOO' };

      testAction(
        actions.blacklistLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches setLicenseApproval for approved licenses', done => {
      const license = approvedLicense;

      testAction(
        actions.blacklistLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('does not dispatch setLicenseApproval for blacklisted licenses', done => {
      testAction(actions.blacklistLicense, blacklistedLicense, state, [], [])
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestLoadManagedLicenses', () => {
    it('commits REQUEST_LOAD_MANAGED_LICENSES', done => {
      testAction(
        actions.requestLoadManagedLicenses,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_MANAGED_LICENSES }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadManagedLicenses', () => {
    it('commits RECEIVE_LOAD_MANAGED_LICENSES', done => {
      const payload = [approvedLicense];
      testAction(
        actions.receiveLoadManagedLicenses,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_MANAGED_LICENSES, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadManagedLicensesError', () => {
    it('commits RECEIVE_LOAD_MANAGED_LICENSES_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveLoadManagedLicensesError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_MANAGED_LICENSES_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadManagedLicenses', () => {
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onGet(apiUrlManageLicenses);
    });

    it('dispatches requestLoadManagedLicenses and receiveLoadManagedLicenses for successful response', done => {
      const payload = [{ name: 'foo', approval_status: LICENSE_APPROVAL_STATUS.BLACKLISTED }];
      endpointMock.replyOnce(() => [200, payload]);

      testAction(
        actions.loadManagedLicenses,
        null,
        state,
        [],
        [{ type: 'requestLoadManagedLicenses' }, { type: 'receiveLoadManagedLicenses', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadManagedLicenses and receiveLoadManagedLicensesError for error response', done => {
      endpointMock.replyOnce(() => [500, '']);

      testAction(
        actions.loadManagedLicenses,
        null,
        state,
        [],
        [
          { type: 'requestLoadManagedLicenses' },
          { type: 'receiveLoadManagedLicensesError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestLoadLicenseReport', () => {
    it('commits REQUEST_LOAD_LICENSE_REPORT', done => {
      testAction(
        actions.requestLoadLicenseReport,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_LICENSE_REPORT }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadLicenseReport', () => {
    it('commits RECEIVE_LOAD_LICENSE_REPORT', done => {
      const payload = { headReport: licenseHeadIssues, baseReport: licenseBaseIssues };
      testAction(
        actions.receiveLoadLicenseReport,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_LICENSE_REPORT, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadLicenseReportError', () => {
    it('commits RECEIVE_LOAD_LICENSE_REPORT_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveLoadLicenseReportError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_LICENSE_REPORT_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadLicenseReport', () => {
    let headMock;
    let baseMock;

    beforeEach(() => {
      headMock = axiosMock.onGet(headPath);
      baseMock = axiosMock.onGet(basePath);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReport for successful response', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [200, licenseBaseIssues]);

      const payload = { headReport: licenseHeadIssues, baseReport: licenseBaseIssues };
      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [{ type: 'requestLoadLicenseReport' }, { type: 'receiveLoadLicenseReport', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReport for 404 on basePath', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [404, null]);

      const payload = { headReport: licenseHeadIssues, baseReport: {} };
      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [{ type: 'requestLoadLicenseReport' }, { type: 'receiveLoadLicenseReport', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReportError for error response on head Path', done => {
      headMock.replyOnce(() => [500, '']);
      baseMock.replyOnce(() => [200, licenseBaseIssues]);

      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [
          { type: 'requestLoadLicenseReport' },
          { type: 'receiveLoadLicenseReportError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReportError for error response on base Path', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [500, '']);

      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [
          { type: 'requestLoadLicenseReport' },
          { type: 'receiveLoadLicenseReportError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });
});
