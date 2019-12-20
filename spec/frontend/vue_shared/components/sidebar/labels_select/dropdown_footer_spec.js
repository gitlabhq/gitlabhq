import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import dropdownFooterComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_footer.vue';

import { mockConfig } from '../../../../../javascripts/vue_shared/components/sidebar/labels_select/mock_data';

const createComponent = (
  labelsWebUrl = mockConfig.labelsWebUrl,
  createLabelTitle,
  manageLabelsTitle,
) => {
  const Component = Vue.extend(dropdownFooterComponent);

  return mountComponent(Component, {
    labelsWebUrl,
    createLabelTitle,
    manageLabelsTitle,
  });
};

describe('DropdownFooterComponent', () => {
  const createLabelTitle = 'Create project label';
  const manageLabelsTitle = 'Manage project labels';
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders link element with `Create new label` when `createLabelTitle` prop is not provided', () => {
      const createLabelEl = vm.$el.querySelector('.dropdown-footer-list .dropdown-toggle-page');

      expect(createLabelEl).not.toBeNull();
      expect(createLabelEl.innerText.trim()).toBe('Create new label');
    });

    it('renders link element with value of `createLabelTitle` prop', () => {
      const vmWithCreateLabelTitle = createComponent(mockConfig.labelsWebUrl, createLabelTitle);
      const createLabelEl = vmWithCreateLabelTitle.$el.querySelector(
        '.dropdown-footer-list .dropdown-toggle-page',
      );

      expect(createLabelEl.innerText.trim()).toBe(createLabelTitle);
      vmWithCreateLabelTitle.$destroy();
    });

    it('renders link element with `Manage labels` when `manageLabelsTitle` prop is not provided', () => {
      const manageLabelsEl = vm.$el.querySelector('.dropdown-footer-list .dropdown-external-link');

      expect(manageLabelsEl).not.toBeNull();
      expect(manageLabelsEl.getAttribute('href')).toBe(vm.labelsWebUrl);
      expect(manageLabelsEl.innerText.trim()).toBe('Manage labels');
    });

    it('renders link element with value of `manageLabelsTitle` prop', () => {
      const vmWithManageLabelsTitle = createComponent(
        mockConfig.labelsWebUrl,
        createLabelTitle,
        manageLabelsTitle,
      );
      const manageLabelsEl = vmWithManageLabelsTitle.$el.querySelector(
        '.dropdown-footer-list .dropdown-external-link',
      );

      expect(manageLabelsEl.innerText.trim()).toBe(manageLabelsTitle);
      vmWithManageLabelsTitle.$destroy();
    });
  });
});
