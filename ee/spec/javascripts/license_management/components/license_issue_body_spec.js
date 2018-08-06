import Vue from 'vue';

import LicenseIssueBody from 'ee/vue_shared/license_management/components/license_issue_body.vue';
import { trimText } from 'spec/helpers/vue_component_helper';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import createStore from 'ee/vue_shared/license_management/store';
import { licenseReport } from 'ee_spec/license_management/mock_data';

describe('LicenseIssueBody', () => {
  const issue = licenseReport[0];
  const Component = Vue.extend(LicenseIssueBody);
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();
    vm = mountComponentWithStore(Component, { props: { issue }, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('interaction', () => {
    it('clicking the button triggers openModal with the current license', () => {
      const linkEl = vm.$el.querySelector('.license-item > .btn-link');

      expect(store.state.currentLicenseInModal).toBe(null);

      linkEl.click();

      expect(store.state.currentLicenseInModal).toBe(issue);
    });
  });

  describe('template', () => {
    it('renders component container element with class `license-item`', () => {
      expect(vm.$el.classList.contains('license-item')).toBe(true);
    });

    it('renders button to open modal', () => {
      const linkEl = vm.$el.querySelector('.license-item > .btn-link');
      expect(linkEl).not.toBeNull();
      expect(linkEl.innerText.trim()).toBe(issue.name);
    });

    it('renders packages list', () => {
      const packagesEl = vm.$el.querySelector('.license-packages');
      expect(packagesEl).not.toBeNull();
      expect(trimText(packagesEl.innerText)).toBe('Used by pg, puma, foo, and 2 more');
    });
  });
});
