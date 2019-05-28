import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import eventHub from '~/clusters/event_hub';
import { APPLICATION_STATUS } from '~/clusters/constants';
import applicationRow from '~/clusters/components/application_row.vue';
import UninstallApplicationConfirmationModal from '~/clusters/components/uninstall_application_confirmation_modal.vue';

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

    it('has loading "Installing" when APPLICATION_STATUS.INSTALLING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLING,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has disabled "Installed" when application is installed and not uninstallable', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLED,
        installed: true,
        uninstallable: false,
      });

      expect(vm.installButtonLabel).toEqual('Installed');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('hides when application is installed and uninstallable', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLED,
        installed: true,
        uninstallable: true,
      });
      const installBtn = vm.$el.querySelector('.js-cluster-application-install-button');

      expect(installBtn).toBe(null);
    });

    it('has enabled "Install" when install fails', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
        installFailed: true,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('has enabled "Install" when REQUEST_FAILURE (so you can try installing again)', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLABLE,
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

  describe('Uninstall button', () => {
    it('displays button when app is installed and uninstallable', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        installed: true,
        uninstallable: true,
        status: APPLICATION_STATUS.NOT_INSTALLABLE,
      });
      const uninstallButton = vm.$el.querySelector('.js-cluster-application-uninstall-button');

      expect(uninstallButton).toBeTruthy();
    });

    it('displays a success toast message if application uninstall was successful', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        title: 'GitLab Runner',
        uninstallSuccessful: false,
      });

      vm.$toast = { show: jest.fn() };
      vm.uninstallSuccessful = true;

      return vm.$nextTick(() => {
        expect(vm.$toast.show).toHaveBeenCalledWith('GitLab Runner uninstalled successfully.');
      });
    });
  });

  describe('when confirmation modal triggers confirm event', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(ApplicationRow, {
        propsData: {
          ...DEFAULT_APPLICATION_STATE,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('triggers uninstallApplication event', () => {
      jest.spyOn(eventHub, '$emit');
      wrapper.find(UninstallApplicationConfirmationModal).vm.$emit('confirm');

      expect(eventHub.$emit).toHaveBeenCalledWith('uninstallApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
      });
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

    it('has enabled "Retry update" when update process fails', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
      });
      const upgradeBtn = vm.$el.querySelector('.js-cluster-application-upgrade-button');

      expect(upgradeBtn).not.toBe(null);
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
        status: APPLICATION_STATUS.INSTALLED,
        upgradeAvailable: true,
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
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
      });
      const failureMessage = vm.$el.querySelector(
        '.js-cluster-application-upgrade-failure-message',
      );

      expect(failureMessage).not.toBe(null);
      expect(failureMessage.innerHTML).toContain(
        'Update failed. Please check the logs and try again.',
      );
    });

    it('displays a success toast message if application upgrade was successful', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        title: 'GitLab Runner',
        updateSuccessful: false,
      });

      vm.$toast = { show: jest.fn() };
      vm.updateSuccessful = true;

      return vm.$nextTick(() => {
        expect(vm.$toast.show).toHaveBeenCalledWith('GitLab Runner upgraded successfully.');
      });
    });
  });

  describe('Version', () => {
    it('displays a version number if application has been upgraded', () => {
      const version = '0.1.45';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_STATUS.INSTALLED,
        updateSuccessful: true,
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
        status: APPLICATION_STATUS.INSTALLED,
        updateSuccessful: true,
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
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
        version,
      });
      const upgradeDetails = vm.$el.querySelector('.js-cluster-application-upgrade-details');
      const versionEl = vm.$el.querySelector('.js-cluster-application-upgrade-version');

      expect(upgradeDetails.innerHTML).toContain('failed');
      expect(versionEl).toBe(null);
    });
  });

  describe('Error block', () => {
    describe('when nothing fails', () => {
      it('does not show error block', () => {
        vm = mountComponent(ApplicationRow, {
          ...DEFAULT_APPLICATION_STATE,
        });
        const generalErrorMessage = vm.$el.querySelector(
          '.js-cluster-application-general-error-message',
        );

        expect(generalErrorMessage).toBeNull();
      });
    });

    describe('when install or uninstall fails', () => {
      const statusReason = 'We broke it 0.0';
      const requestReason = 'We broke the request 0.0';

      beforeEach(() => {
        vm = mountComponent(ApplicationRow, {
          ...DEFAULT_APPLICATION_STATE,
          status: APPLICATION_STATUS.ERROR,
          statusReason,
          requestReason,
          installFailed: true,
        });
      });

      it('shows status reason if it is available', () => {
        const statusErrorMessage = vm.$el.querySelector(
          '.js-cluster-application-status-error-message',
        );

        expect(statusErrorMessage.textContent.trim()).toEqual(statusReason);
      });

      it('shows request reason if it is available', () => {
        const requestErrorMessage = vm.$el.querySelector(
          '.js-cluster-application-request-error-message',
        );

        expect(requestErrorMessage.textContent.trim()).toEqual(requestReason);
      });
    });

    describe('when install fails', () => {
      beforeEach(() => {
        vm = mountComponent(ApplicationRow, {
          ...DEFAULT_APPLICATION_STATE,
          status: APPLICATION_STATUS.ERROR,
          installFailed: true,
        });
      });

      it('shows a general message indicating the installation failed', () => {
        const generalErrorMessage = vm.$el.querySelector(
          '.js-cluster-application-general-error-message',
        );

        expect(generalErrorMessage.textContent.trim()).toEqual(
          `Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`,
        );
      });
    });

    describe('when uninstall fails', () => {
      beforeEach(() => {
        vm = mountComponent(ApplicationRow, {
          ...DEFAULT_APPLICATION_STATE,
          status: APPLICATION_STATUS.ERROR,
          uninstallFailed: true,
        });
      });

      it('shows a general message indicating the uninstalling failed', () => {
        const generalErrorMessage = vm.$el.querySelector(
          '.js-cluster-application-general-error-message',
        );

        expect(generalErrorMessage.textContent.trim()).toEqual(
          `Something went wrong while uninstalling ${DEFAULT_APPLICATION_STATE.title}`,
        );
      });
    });
  });
});
