import Vue from 'vue';

import LicensePackages from 'ee/vue_shared/license_management/components/license_packages.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { licenseReport } from 'ee_spec/license_management/mock_data';

const examplePackages = licenseReport[0].packages;

const createComponent = (packages = examplePackages) => {
  const Component = Vue.extend(LicensePackages);

  return mountComponent(Component, { packages });
};

describe('LicensePackages', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('remainingPackages', () => {
      it('returns string with count of packages when it exceeds `displayPackageCount` prop', () => {
        expect(vm.remainingPackages).toBe('2 more');
      });

      it('returns empty string when count of packages does not exceed `displayPackageCount` prop', done => {
        vm.displayPackageCount = examplePackages.length + 1;
        Vue.nextTick()
          .then(() => {
            expect(vm.remainingPackages).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('methods', () => {
    describe('handleShowPackages', () => {
      it('sets value of `showAllPackages` prop to true', () => {
        vm.showAllPackages = false;
        vm.handleShowPackages();
        expect(vm.showAllPackages).toBe(true);
      });
    });
  });

  describe('template', () => {
    it('renders packages list for a particular license', () => {
      const packagesEl = vm.$el.querySelector('.js-license-dependencies');
      expect(packagesEl).not.toBeNull();
      expect(packagesEl.innerText.trim()).toBe('Used by pg, puma, foo, and');
    });

    it('renders more packages button element', () => {
      const buttonEl = vm.$el.querySelector('.btn-show-all-packages');
      expect(buttonEl).not.toBeNull();
      expect(buttonEl.innerText.trim()).toBe('2 more');
    });
  });
});
