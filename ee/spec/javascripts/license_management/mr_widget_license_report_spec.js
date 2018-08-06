import Vue from 'vue';
import Vuex from 'vuex';

import LicenseManagement from 'ee/vue_shared/license_management/mr_widget_license_report.vue';
import { LOADING, ERROR, SUCCESS } from 'ee/vue_shared/security_reports/store/constants';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import {
  approvedLicense,
  blacklistedLicense,
  licenseReport as licenseReportMock,
} from 'ee_spec/license_management/mock_data';

describe('License Report MR Widget', () => {
  const Component = Vue.extend(LicenseManagement);
  const apiUrl = `${TEST_HOST}/license_management`;
  let vm;
  let store;
  let actions;
  let getters;
  const props = {
    loadingText: 'LOADING',
    errorText: 'ERROR',
    headPath: `${TEST_HOST}/head.json`,
    basePath: `${TEST_HOST}/head.json`,
    canManageLicenses: true,
    apiUrl,
  };

  beforeEach(() => {
    actions = {
      setAPISettings: jasmine.createSpy('setAPISettings').and.callFake(() => {}),
      loadManagedLicenses: jasmine.createSpy('loadManagedLicenses').and.callFake(() => {}),
      loadLicenseReport: jasmine.createSpy('loadLicenseReport').and.callFake(() => {}),
    };
    getters = {
      isLoading() {
        return false;
      },
      licenseReport() {
        return licenseReportMock;
      },
      licenseSummaryText() {
        return 'FOO';
      },
    };
    store = new Vuex.Store({
      state: {
        managedLicenses: [approvedLicense, blacklistedLicense],
        currentLicenseInModal: licenseReportMock[0],
        isLoadingManagedLicenses: true,
      },
      getters,
      actions,
    });
    vm = mountComponentWithStore(Component, { props, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasLicenseReportIssues', () => {
      it('should be false, if the report is empty', done => {
        store.hotUpdate({
          getters: {
            ...getters,
            licenseReport() {
              return [];
            },
          },
        });
        return Vue.nextTick().then(() => {
          expect(vm.hasLicenseReportIssues).toBe(false);
          done();
        });
      });

      it('should be true, if the report is not empty', done =>
        Vue.nextTick().then(() => {
          expect(vm.hasLicenseReportIssues).toBe(true);
          done();
        }));
    });

    describe('licensesTab', () => {
      it('with the pipelinePath prop', done => {
        const pipelinePath = `${TEST_HOST}/path/to/the/pipeline`;

        vm.pipelinePath = pipelinePath;

        return Vue.nextTick().then(() => {
          expect(vm.licensesTab).toEqual(`${pipelinePath}/licenses`);
          done();
        });
      });

      it('without the pipelinePath prop', () => {
        expect(vm.licensesTab).toEqual(null);
      });
    });

    describe('licenseReportStatus', () => {
      it('should be `LOADING`, if the report is loading', done => {
        store.hotUpdate({
          getters: {
            ...getters,
            isLoading() {
              return true;
            },
          },
        });
        return Vue.nextTick().then(() => {
          expect(vm.licenseReportStatus).toBe(LOADING);
          done();
        });
      });

      it('should be `ERROR`, if the report is has an error', done => {
        store.replaceState({ ...store.state, loadLicenseReportError: new Error('test') });
        return Vue.nextTick().then(() => {
          expect(vm.licenseReportStatus).toBe(ERROR);
          done();
        });
      });

      it('should be `SUCCESS`, if the report is successful', done =>
        Vue.nextTick().then(() => {
          expect(vm.licenseReportStatus).toBe(SUCCESS);
          done();
        }));
    });
  });

  it('should render report section wrapper', done =>
    Vue.nextTick().then(() => {
      expect(vm.$el.querySelector('.license-report-widget')).not.toBeNull();
      done();
    }));

  it('should render report widget section', done =>
    Vue.nextTick().then(() => {
      expect(vm.$el.querySelector('.report-block-container')).not.toBeNull();
      done();
    }));

  it('should render set approval modal', done => {
    store.replaceState({ ...store.state });

    return Vue.nextTick().then(() => {
      expect(vm.$el.querySelector('#modal-set-license-approval')).not.toBeNull();
      done();
    });
  });

  it('should init store after mount', () =>
    Vue.nextTick().then(() => {
      expect(actions.setAPISettings).toHaveBeenCalledWith(
        jasmine.any(Object),
        {
          apiUrlManageLicenses: apiUrl,
          headPath: props.headPath,
          basePath: props.basePath,
          canManageLicenses: true,
        },
        undefined,
      );
      expect(actions.loadManagedLicenses).toHaveBeenCalledWith(
        jasmine.any(Object),
        undefined,
        undefined,
      );
      expect(actions.loadLicenseReport).toHaveBeenCalledWith(
        jasmine.any(Object),
        undefined,
        undefined,
      );
    }));
});
