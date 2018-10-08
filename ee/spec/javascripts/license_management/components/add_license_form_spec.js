import Vue from 'vue';
import LicenseIssueBody from 'ee/vue_shared/license_management/components/add_license_form.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

describe('AddLicenseForm', () => {
  const Component = Vue.extend(LicenseIssueBody);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('interaction', () => {
    it('clicking the Submit button submits the data and closes the form', done => {
      const name = 'LICENSE_TEST';
      spyOn(vm, '$emit');
      vm.approvalStatus = LICENSE_APPROVAL_STATUS.APPROVED;
      vm.licenseName = name;

      Vue.nextTick(() => {
        const linkEl = vm.$el.querySelector('.js-submit');
        linkEl.click();

        expect(vm.$emit).toHaveBeenCalledWith('addLicense', {
          newStatus: LICENSE_APPROVAL_STATUS.APPROVED,
          license: { name },
        });
        expect(vm.$emit).toHaveBeenCalledWith('closeForm');
        done();
      });
    });

    it('clicking the Cancel button closes the form', () => {
      const linkEl = vm.$el.querySelector('.js-cancel');
      spyOn(vm, '$emit');
      linkEl.click();

      expect(vm.$emit).toHaveBeenCalledWith('closeForm');
    });
  });

  describe('computed', () => {
    describe('submitDisabled', () => {
      it('is true if the approvalStatus is empty', () => {
        vm.licenseName = 'FOO';
        vm.approvalStatus = '';
        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the licenseName is empty', () => {
        vm.licenseName = '';
        vm.approvalStatus = LICENSE_APPROVAL_STATUS.APPROVED;
        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the entered license is duplicated', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO';
        vm.approvalStatus = LICENSE_APPROVAL_STATUS.APPROVED;
        expect(vm.submitDisabled).toBe(true);
      });
    });

    describe('isInvalidLicense', () => {
      it('is true if the entered license is duplicated', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO';
        expect(vm.isInvalidLicense).toBe(true);
      });

      it('is false if the entered license is unique', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO2';
        expect(vm.isInvalidLicense).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders the license select dropdown', () => {
      const dropdownElement = vm.$el.querySelector('#js-license-dropdown');
      expect(dropdownElement).not.toBeNull();
    });

    it('renders the license approval radio buttons dropdown', () => {
      const radioButtonParents = vm.$el.querySelectorAll('.form-check');
      expect(radioButtonParents.length).toBe(2);
      expect(radioButtonParents[0].innerText.trim()).toBe('Approve');
      expect(radioButtonParents[0].querySelector('.form-check-input')).not.toBeNull();
      expect(radioButtonParents[1].innerText.trim()).toBe('Blacklist');
      expect(radioButtonParents[1].querySelector('.form-check-input')).not.toBeNull();
    });

    it('renders error text, if there is a duplicate license', done => {
      vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
      vm.licenseName = 'FOO';
      Vue.nextTick(() => {
        const feedbackElement = vm.$el.querySelector('.invalid-feedback');
        expect(feedbackElement).not.toBeNull();
        expect(feedbackElement.classList).toContain('d-block');
        expect(feedbackElement.innerText.trim()).toBe(
          'This license already exists in this project.',
        );
        done();
      });
    });

    it('disables submit, if the form is invalid', done => {
      vm.licenseName = '';
      Vue.nextTick(() => {
        expect(vm.submitDisabled).toBe(true);

        const submitButton = vm.$el.querySelector('.js-submit');
        expect(submitButton).not.toBeNull();
        expect(submitButton.disabled).toBe(true);
        done();
      });
    });
  });
});
