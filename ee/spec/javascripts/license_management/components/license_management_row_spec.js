import Vue from 'vue';
import Vuex from 'vuex';

import LicenseManagementRow from 'ee/vue_shared/license_management/components/license_management_row.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { approvedLicense } from 'ee_spec/license_management/mock_data';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

describe('LicenseManagementRow', () => {
  const Component = Vue.extend(LicenseManagementRow);

  let vm;
  let store;
  let actions;

  beforeEach(() => {
    actions = {
      setLicenseInModal: jasmine.createSpy('setLicenseInModal'),
      approveLicense: jasmine.createSpy('approveLicense'),
      blacklistLicense: jasmine.createSpy('blacklistLicense'),
    };

    store = new Vuex.Store({
      state: {},
      actions,
    });

    const props = { license: approvedLicense };

    vm = mountComponentWithStore(Component, { props, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('approved license', () => {
    beforeEach(done => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.APPROVED };
      Vue.nextTick(done);
    });

    describe('computed', () => {
      it('dropdownText returns `Approved`', () => {
        expect(vm.dropdownText).toBe('Approved');
      });

      it('isApproved returns `true`', () => {
        expect(vm.approveIconClass).toBe(visibleClass);
      });

      it('isBlacklisted returns `false`', () => {
        expect(vm.blacklistIconClass).toBe(invisibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have a visible icon', () => {
        const firstOption = vm.$el.querySelector('.dropdown-item:nth-child(1) svg');
        expect(firstOption.classList).toContain(visibleClass);
      });

      it('second dropdown element should have no visible icon', () => {
        const secondOption = vm.$el.querySelector('.dropdown-item:nth-child(2) svg');
        expect(secondOption.classList).toContain(invisibleClass);
      });
    });
  });

  describe('blacklisted license', () => {
    beforeEach(done => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED };
      Vue.nextTick(done);
    });

    describe('computed', () => {
      it('dropdownText returns `Blacklisted`', () => {
        expect(vm.dropdownText).toBe('Blacklisted');
      });

      it('isApproved returns `false`', () => {
        expect(vm.approveIconClass).toBe(invisibleClass);
      });

      it('isBlacklisted returns `true`', () => {
        expect(vm.blacklistIconClass).toBe(visibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have no visible icon', () => {
        const firstOption = vm.$el.querySelector('.dropdown-item:nth-child(1) svg');
        expect(firstOption.classList).toContain(invisibleClass);
      });

      it('second dropdown element should have a visible icon', () => {
        const secondOption = vm.$el.querySelector('.dropdown-item:nth-child(2) svg');
        expect(secondOption.classList).toContain(visibleClass);
      });
    });
  });

  describe('interaction', () => {
    it('triggering setLicenseInModal by clicking the cancel button', () => {
      const linkEl = vm.$el.querySelector('.js-remove-button');
      linkEl.click();
      expect(actions.setLicenseInModal).toHaveBeenCalled();
    });
    it('triggering approveLicense by clicking the first dropdown option', () => {
      const linkEl = vm.$el.querySelector('.dropdown-item:nth-child(1)');
      linkEl.click();
      expect(actions.approveLicense).toHaveBeenCalled();
    });

    it('triggering approveLicense blacklistLicense by clicking the second dropdown option', () => {
      const linkEl = vm.$el.querySelector('.dropdown-item:nth-child(2)');
      linkEl.click();
      expect(actions.blacklistLicense).toHaveBeenCalled();
    });
  });

  describe('template', () => {
    it('renders component container element with class `list-group-item`', () => {
      expect(vm.$el.classList.contains('list-group-item')).toBe(true);
    });

    it('renders status icon', () => {
      const iconEl = vm.$el.querySelector('.report-block-list-icon');
      expect(iconEl).not.toBeNull();
    });

    it('renders license name', () => {
      const nameEl = vm.$el.querySelector('.js-license-name');
      expect(nameEl.innerText.trim()).toBe(approvedLicense.name);
    });

    it('renders the removal button', () => {
      const buttonEl = vm.$el.querySelector('.js-remove-button');
      expect(buttonEl).not.toBeNull();
      expect(buttonEl.querySelector('.ic-remove')).not.toBeNull();
    });

    it('renders computed property dropdownText into dropdown toggle', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown [data-toggle="dropdown"]');
      expect(dropdownEl.innerText.trim()).toBe(vm.dropdownText);
    });

    it('renders the dropdown with `Approved` and `Blacklisted` options', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown');
      expect(dropdownEl).not.toBeNull();

      const firstOption = dropdownEl.querySelector('.dropdown-item:nth-child(1)');
      expect(firstOption).not.toBeNull();
      expect(firstOption.innerText.trim()).toBe('Approved');

      const secondOption = dropdownEl.querySelector('.dropdown-item:nth-child(2)');
      expect(secondOption).not.toBeNull();
      expect(secondOption.innerText.trim()).toBe('Blacklisted');
    });
  });
});
