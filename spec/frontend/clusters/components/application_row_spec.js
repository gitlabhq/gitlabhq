import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApplicationRow from '~/clusters/components/application_row.vue';
import UninstallApplicationConfirmationModal from '~/clusters/components/uninstall_application_confirmation_modal.vue';
import UpdateApplicationConfirmationModal from '~/clusters/components/update_application_confirmation_modal.vue';
import { APPLICATION_STATUS, ELASTIC_STACK } from '~/clusters/constants';
import eventHub from '~/clusters/event_hub';

import { DEFAULT_APPLICATION_STATE } from '../services/mock_data';

describe('Application Row', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const mountComponent = (data) => {
    wrapper = shallowMount(ApplicationRow, {
      stubs: { GlSprintf },
      propsData: {
        ...DEFAULT_APPLICATION_STATE,
        ...data,
      },
    });
  };

  describe('Title', () => {
    it('shows title', () => {
      mountComponent({ titleLink: null });

      const title = wrapper.find('.js-cluster-application-title');

      expect(title.element).toBeInstanceOf(HTMLSpanElement);
      expect(title.text()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });

    it('shows title link', () => {
      expect(DEFAULT_APPLICATION_STATE.titleLink).toBeDefined();
      mountComponent();
      const title = wrapper.find('.js-cluster-application-title');

      expect(title.element).toBeInstanceOf(HTMLAnchorElement);
      expect(title.text()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });
  });

  describe('Install button', () => {
    const button = () => wrapper.find('.js-cluster-application-install-button');
    const checkButtonState = (label, loading, disabled) => {
      expect(button().text()).toEqual(label);
      expect(button().props('loading')).toEqual(loading);
      expect(button().props('disabled')).toEqual(disabled);
    };

    it('has indeterminate state on page load', () => {
      mountComponent({ status: null });

      expect(button().text()).toBe('');
    });

    it('has install button', () => {
      mountComponent();

      expect(button().exists()).toBe(true);
    });

    it('has disabled "Install" when APPLICATION_STATUS.NOT_INSTALLABLE', () => {
      mountComponent({ status: APPLICATION_STATUS.NOT_INSTALLABLE });

      checkButtonState('Install', false, true);
    });

    it('has enabled "Install" when APPLICATION_STATUS.INSTALLABLE', () => {
      mountComponent({ status: APPLICATION_STATUS.INSTALLABLE });

      checkButtonState('Install', false, false);
    });

    it('has loading "Installing" when APPLICATION_STATUS.INSTALLING', () => {
      mountComponent({ status: APPLICATION_STATUS.INSTALLING });

      checkButtonState('Installing', true, true);
    });

    it('has disabled "Install" when APPLICATION_STATUS.UNINSTALLED', () => {
      mountComponent({ status: APPLICATION_STATUS.UNINSTALLED });

      checkButtonState('Install', false, true);
    });

    it('has disabled "Externally installed" when APPLICATION_STATUS.EXTERNALLY_INSTALLED', () => {
      mountComponent({ status: APPLICATION_STATUS.EXTERNALLY_INSTALLED });

      checkButtonState('Externally installed', false, true);
    });

    it('has disabled "Installed" when application is installed and not uninstallable', () => {
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        installed: true,
        uninstallable: false,
      });

      checkButtonState('Installed', false, true);
    });

    it('hides when application is installed and uninstallable', () => {
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        installed: true,
        uninstallable: true,
      });

      expect(button().exists()).toBe(false);
    });

    it('has enabled "Install" when install fails', () => {
      mountComponent({
        status: APPLICATION_STATUS.INSTALLABLE,
        installFailed: true,
      });

      checkButtonState('Install', false, false);
    });

    it('has disabled "Install" when installation disabled', () => {
      mountComponent({
        status: APPLICATION_STATUS.INSTALLABLE,
        installable: false,
      });

      checkButtonState('Install', false, true);
    });

    it('has enabled "Install" when REQUEST_FAILURE (so you can try installing again)', () => {
      mountComponent({ status: APPLICATION_STATUS.INSTALLABLE });

      checkButtonState('Install', false, false);
    });

    it('clicking install button emits event', () => {
      const spy = jest.spyOn(eventHub, '$emit');
      mountComponent({ status: APPLICATION_STATUS.INSTALLABLE });

      button().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('installApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: {},
      });
    });

    it('clicking install button when installApplicationRequestParams are provided emits event', () => {
      const spy = jest.spyOn(eventHub, '$emit');
      mountComponent({
        status: APPLICATION_STATUS.INSTALLABLE,
        installApplicationRequestParams: { hostname: 'jupyter' },
      });

      button().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('installApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: { hostname: 'jupyter' },
      });
    });

    it('clicking disabled install button emits nothing', () => {
      const spy = jest.spyOn(eventHub, '$emit');
      mountComponent({ status: APPLICATION_STATUS.INSTALLING });

      expect(button().props('disabled')).toEqual(true);

      button().vm.$emit('click');

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('Uninstall button', () => {
    it('displays button when app is installed and uninstallable', () => {
      mountComponent({
        installed: true,
        uninstallable: true,
        status: APPLICATION_STATUS.NOT_INSTALLABLE,
      });
      const uninstallButton = wrapper.find('.js-cluster-application-uninstall-button');

      expect(uninstallButton.exists()).toBe(true);
    });

    it('displays a success toast message if application uninstall was successful', async () => {
      mountComponent({
        title: 'GitLab Runner',
        uninstallSuccessful: false,
      });

      wrapper.vm.$toast = { show: jest.fn() };
      wrapper.setProps({ uninstallSuccessful: true });

      await wrapper.vm.$nextTick();
      expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
        'GitLab Runner uninstalled successfully.',
      );
    });
  });

  describe('when confirmation modal triggers confirm event', () => {
    it('triggers uninstallApplication event', () => {
      jest.spyOn(eventHub, '$emit');
      mountComponent();
      wrapper.find(UninstallApplicationConfirmationModal).vm.$emit('confirm');

      expect(eventHub.$emit).toHaveBeenCalledWith('uninstallApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
      });
    });
  });

  describe('Update button', () => {
    const button = () => wrapper.find('.js-cluster-application-update-button');

    it('has indeterminate state on page load', () => {
      mountComponent();

      expect(button().exists()).toBe(false);
    });

    it('has enabled "Update" when "updateAvailable" is true', () => {
      mountComponent({ updateAvailable: true });

      expect(button().exists()).toBe(true);
      expect(button().text()).toContain('Update');
    });

    it('has enabled "Retry update" when update process fails', () => {
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
      });

      expect(button().exists()).toBe(true);
      expect(button().text()).toContain('Retry update');
    });

    it('has disabled "Updating" when APPLICATION_STATUS.UPDATING', () => {
      mountComponent({ status: APPLICATION_STATUS.UPDATING });

      expect(button().exists()).toBe(true);
      expect(button().text()).toContain('Updating');
    });

    it('clicking update button emits event', () => {
      const spy = jest.spyOn(eventHub, '$emit');
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        updateAvailable: true,
      });

      button().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('updateApplication', {
        id: DEFAULT_APPLICATION_STATE.id,
        params: {},
      });
    });

    it('clicking disabled update button emits nothing', () => {
      const spy = jest.spyOn(eventHub, '$emit');
      mountComponent({ status: APPLICATION_STATUS.UPDATING });

      button().vm.$emit('click');

      expect(spy).not.toHaveBeenCalled();
    });

    it('displays an error message if application update failed', () => {
      mountComponent({
        title: 'GitLab Runner',
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
      });
      const failureMessage = wrapper.find('.js-cluster-application-update-details');

      expect(failureMessage.exists()).toBe(true);
      expect(failureMessage.text()).toContain(
        'Update failed. Please check the logs and try again.',
      );
    });

    it('displays a success toast message if application update was successful', async () => {
      mountComponent({
        title: 'GitLab Runner',
        updateSuccessful: false,
      });

      wrapper.vm.$toast = { show: jest.fn() };
      wrapper.setProps({ updateSuccessful: true });

      await wrapper.vm.$nextTick();
      expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('GitLab Runner updated successfully.');
    });

    describe('when updating does not require confirmation', () => {
      beforeEach(() => mountComponent({ updateAvailable: true }));

      it('the modal is not rendered', () => {
        expect(wrapper.find(UpdateApplicationConfirmationModal).exists()).toBe(false);
      });

      it('the correct button is rendered', () => {
        expect(wrapper.find("[data-qa-selector='update_button']").exists()).toBe(true);
      });
    });

    describe('when updating requires confirmation', () => {
      beforeEach(() => {
        mountComponent({
          updateAvailable: true,
          id: ELASTIC_STACK,
          version: '1.1.2',
        });
      });

      it('displays a modal', () => {
        expect(wrapper.find(UpdateApplicationConfirmationModal).exists()).toBe(true);
      });

      it('the correct button is rendered', () => {
        expect(wrapper.find("[data-qa-selector='update_button_with_confirmation']").exists()).toBe(
          true,
        );
      });

      it('triggers updateApplication event', () => {
        jest.spyOn(eventHub, '$emit');
        wrapper.find(UpdateApplicationConfirmationModal).vm.$emit('confirm');

        expect(eventHub.$emit).toHaveBeenCalledWith('updateApplication', {
          id: ELASTIC_STACK,
          params: {},
        });
      });
    });

    describe('updating Elastic Stack special case', () => {
      it('needs confirmation if version is lower than 3.0.0', () => {
        mountComponent({
          updateAvailable: true,
          id: ELASTIC_STACK,
          version: '1.1.2',
        });

        expect(wrapper.find("[data-qa-selector='update_button_with_confirmation']").exists()).toBe(
          true,
        );
        expect(wrapper.find(UpdateApplicationConfirmationModal).exists()).toBe(true);
      });

      it('does not need confirmation is version is 3.0.0', () => {
        mountComponent({
          updateAvailable: true,
          id: ELASTIC_STACK,
          version: '3.0.0',
        });

        expect(wrapper.find("[data-qa-selector='update_button']").exists()).toBe(true);
        expect(wrapper.find(UpdateApplicationConfirmationModal).exists()).toBe(false);
      });

      it('does not need confirmation if version is higher than 3.0.0', () => {
        mountComponent({
          updateAvailable: true,
          id: ELASTIC_STACK,
          version: '5.2.1',
        });

        expect(wrapper.find("[data-qa-selector='update_button']").exists()).toBe(true);
        expect(wrapper.find(UpdateApplicationConfirmationModal).exists()).toBe(false);
      });
    });
  });

  describe('Version', () => {
    const updateDetails = () => wrapper.find('.js-cluster-application-update-details');
    const versionEl = () => wrapper.find('.js-cluster-application-update-version');

    it('displays a version number if application has been updated', () => {
      const version = '0.1.45';
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        updateSuccessful: true,
        version,
      });

      expect(updateDetails().text()).toBe(`Updated to chart v${version}`);
    });

    it('contains a link to the chart repo if application has been updated', () => {
      const version = '0.1.45';
      const chartRepo = 'https://gitlab.com/gitlab-org/charts/gitlab-runner';
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        updateSuccessful: true,
        chartRepo,
        version,
      });

      expect(versionEl().attributes('href')).toEqual(chartRepo);
      expect(versionEl().props('target')).toEqual('_blank');
    });

    it('does not display a version number if application update failed', () => {
      const version = '0.1.45';
      mountComponent({
        status: APPLICATION_STATUS.INSTALLED,
        updateFailed: true,
        version,
      });

      expect(updateDetails().text()).toBe('Update failed');
      expect(versionEl().exists()).toBe(false);
    });

    it('displays updating when the application update is currently updating', () => {
      mountComponent({
        status: APPLICATION_STATUS.UPDATING,
        updateSuccessful: true,
        version: '1.2.3',
      });

      expect(updateDetails().text()).toBe('Updating');
      expect(versionEl().exists()).toBe(false);
    });
  });

  describe('Error block', () => {
    const generalErrorMessage = () => wrapper.find('.js-cluster-application-general-error-message');

    describe('when nothing fails', () => {
      it('does not show error block', () => {
        mountComponent();

        expect(generalErrorMessage().exists()).toBe(false);
      });
    });

    describe('when install or uninstall fails', () => {
      const statusReason = 'We broke it 0.0';
      const requestReason = 'We broke the request 0.0';

      beforeEach(() => {
        mountComponent({
          status: APPLICATION_STATUS.ERROR,
          statusReason,
          requestReason,
          installFailed: true,
        });
      });

      it('shows status reason if it is available', () => {
        const statusErrorMessage = wrapper.find('.js-cluster-application-status-error-message');

        expect(statusErrorMessage.text()).toEqual(statusReason);
      });

      it('shows request reason if it is available', () => {
        const requestErrorMessage = wrapper.find('.js-cluster-application-request-error-message');

        expect(requestErrorMessage.text()).toEqual(requestReason);
      });
    });

    describe('when install fails', () => {
      beforeEach(() => {
        mountComponent({
          status: APPLICATION_STATUS.ERROR,
          installFailed: true,
        });
      });

      it('shows a general message indicating the installation failed', () => {
        expect(generalErrorMessage().text()).toEqual(
          `Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`,
        );
      });
    });

    describe('when uninstall fails', () => {
      beforeEach(() => {
        mountComponent({
          status: APPLICATION_STATUS.ERROR,
          uninstallFailed: true,
        });
      });

      it('shows a general message indicating the uninstalling failed', () => {
        expect(generalErrorMessage().text()).toEqual(
          `Something went wrong while uninstalling ${DEFAULT_APPLICATION_STATE.title}`,
        );
      });
    });
  });
});
