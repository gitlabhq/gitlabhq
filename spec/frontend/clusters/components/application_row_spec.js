import Vue from 'vue';
import eventHub from '~/clusters/event_hub';
import { APPLICATION_STATUS, REQUEST_SUBMITTED, REQUEST_FAILURE } from '~/clusters/constants';
import applicationRow from '~/clusters/components/application_row.vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { DEFAULT_APPLICATION_STATE } from '../services/mock_data';

describe('Application Row', () => {
  let vm;
  let ApplicationRow;

  beforeEach(() => {
    ApplicationRow = Vue.extend(applicationRow);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Title', () => {
    it('shows title', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        titleLink: null,
      });
      const title = vm.$el.querySelector('.js-cluster-application-title');

      expect(title.tagName).toEqual('SPAN');
      expect(title.textContent.trim()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });

    it('shows title link', () => {
      expect(DEFAULT_APPLICATION_STATE.titleLink).toBeDefined();

      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
      });
      const title = vm.$el.querySelector('.js-cluster-application-title');

      expect(title.tagName).toEqual('A');
      expect(title.textContent.trim()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });
  });

  describe('Install button', () => {
    it('has indeterminate state on page load', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: null,
      });

      expect(vm.installButtonLabel).toBeUndefined();
    });

    it('has install button', () => {
      const installationBtn = vm.$el.querySelector('.js-cluster-application-install-button');

      expect(installationBtn).not.toBe(null);
    });

    it('has disabled "Install" when APPLICATION_STATUS.NOT_INSTALLABLE', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.NOT_INSTALLABLE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has enabled "Install" when APPLICATION_STATUS.INSTALLABLE', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('has loading "Installing" when APPLICATION_STATUS.SCHEDULED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.SCHEDULED,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has loading "Installing" when APPLICATION_STATUS.INSTALLING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLING,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has loading "Installing" when REQUEST_SUBMITTED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
        requestStatus: REQUEST_SUBMITTED,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has disabled "Installed" when APPLICATION_STATUS.INSTALLED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLED,
      });

      expect(vm.installButtonLabel).toEqual('Installed');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has disabled "Installed" when APPLICATION_STATUS.UPDATING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATING,
      });

      expect(vm.installButtonLabel).toEqual('Installed');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has enabled "Install" when APPLICATION_STATUS.ERROR', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.ERROR,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('has enabled "Install" when REQUEST_FAILURE (so you can try installing again)', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
        requestStatus: REQUEST_FAILURE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('clicking install button emits event', () => {
      jest.spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
      });
      const installButton = vm.$el.querySelector('.js-cluster-application-install-button');

      installButton.click();

      expect(eventHub.$emit).toHaveBeenCalledWith('installApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: {},
      });
    });

    it('clicking install button when installApplicationRequestParams are provided emits event', () => {
      jest.spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
        installApplicationRequestParams: { hostname: 'jupyter' },
      });
      const installButton = vm.$el.querySelector('.js-cluster-application-install-button');

      installButton.click();

      expect(eventHub.$emit).toHaveBeenCalledWith('installApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: { hostname: 'jupyter' },
      });
    });

    it('clicking disabled install button emits nothing', () => {
      jest.spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLING,
      });
      const installButton = vm.$el.querySelector('.js-cluster-application-install-button');

      expect(vm.installButtonDisabled).toEqual(true);

      installButton.click();

      expect(eventHub.$emit).not.toHaveBeenCalled();
    });
  });

  describe('Upgrade button', () => {
    it('has indeterminate state on page load', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: null,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      expect(upgradeBtn).toBe(null);
    });

    it('has enabled "Upgrade" when "upgradeAvailable" is true', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        upgradeAvailable: true,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      expect(upgradeBtn).not.toBe(null);
      expect(upgradeBtn.innerHTML).toContain('Upgrade');
    });

    it('has enabled "Retry update" when APPLICATION_STATUS.UPDATE_ERRORED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATE_ERRORED,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      expect(upgradeBtn).not.toBe(null);
      expect(vm.upgradeFailed).toBe(true);
      expect(upgradeBtn.innerHTML).toContain('Retry update');
    });

    it('has disabled "Updating" when APPLICATION_STATUS.UPDATING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATING,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      expect(upgradeBtn).not.toBe(null);
      expect(vm.isUpgrading).toBe(true);
      expect(upgradeBtn.innerHTML).toContain('Updating');
    });

    it('clicking upgrade button emits event', () => {
      jest.spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATE_ERRORED,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      upgradeBtn.click();

      expect(eventHub.$emit).toHaveBeenCalledWith('upgradeApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: {},
      });
    });

    it('clicking disabled upgrade button emits nothing', () => {
      jest.spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATING,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      upgradeBtn.click();

      expect(eventHub.$emit).not.toHaveBeenCalled();
    });

    it('displays an error message if application upgrade failed', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        title: 'GitLab Runner',
        status: APPLICATION_STATUS.UPDATE_ERRORED,
      });
      const failureMessage = vm.$el.querySelector(
        '.js-cluster-application-upgrade-failure-message',
      );

      expect(failureMessage).not.toBe(null);
      expect(failureMessage.innerHTML).toContain(
        'Update failed. Please check the logs and try again.',
      );
    });
  });

  describe('Version', () => {
    it('displays a version number if application has been upgraded', () => {
      const version = '0.1.45';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATED,
        version,
      });
      const upgradeDetails = vm.$el.querySelector('.js-cluster-application-upgrade-details');
      const versionEl = vm.$el.querySelector('.js-cluster-application-upgrade-version');

      expect(upgradeDetails.innerHTML).toContain('Upgraded');
      expect(versionEl).not.toBe(null);
      expect(versionEl.innerHTML).toContain(version);
    });

    it('contains a link to the chart repo if application has been upgraded', () => {
      const version = '0.1.45';
      const chartRepo = 'https://gitlab.com/charts/gitlab-runner';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATED,
        chartRepo,
        version,
      });
      const versionEl = vm.$el.querySelector('.js-cluster-application-upgrade-version');

      expect(versionEl.href).toEqual(chartRepo);
      expect(versionEl.target).toEqual('_blank');
    });

    it('does not display a version number if application upgrade failed', () => {
      const version = '0.1.45';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.UPDATE_ERRORED,
        version,
      });
      const upgradeDetails = vm.$el.querySelector('.js-cluster-application-upgrade-details');
      const versionEl = vm.$el.querySelector('.js-cluster-application-upgrade-version');

      expect(upgradeDetails.innerHTML).toContain('failed');
      expect(versionEl).toBe(null);
    });
  });

  describe('Error block', () => {
    it('does not show error block when there is no error', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: null,
        requestStatus: null,
      });
      const generalErrorMessage = vm.$el.querySelector(
        '.js-cluster-application-general-error-message',
      );

      expect(generalErrorMessage).toBeNull();
    });

    it('shows status reason when APPLICATION_STATUS.ERROR', () => {
      const statusReason = 'We broke it 0.0';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.ERROR,
        statusReason,
      });
      const generalErrorMessage = vm.$el.querySelector(
        '.js-cluster-application-general-error-message',
      );
      const statusErrorMessage = vm.$el.querySelector(
        '.js-cluster-application-status-error-message',
      );

      expect(generalErrorMessage.textContent.trim()).toEqual(
        `Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`,
      );

      expect(statusErrorMessage.textContent.trim()).toEqual(statusReason);
    });

    it('shows request reason when REQUEST_FAILURE', () => {
      const requestReason = 'We broke thre request 0.0';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
        requestStatus: REQUEST_FAILURE,
        requestReason,
      });
      const generalErrorMessage = vm.$el.querySelector(
        '.js-cluster-application-general-error-message',
      );
      const requestErrorMessage = vm.$el.querySelector(
        '.js-cluster-application-request-error-message',
      );

      expect(generalErrorMessage.textContent.trim()).toEqual(
        `Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`,
      );

      expect(requestErrorMessage.textContent.trim()).toEqual(requestReason);
    });
  });
});
