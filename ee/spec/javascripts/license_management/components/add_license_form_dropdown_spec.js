import Vue from 'vue';
import $ from 'jquery';
import Dropdown from 'ee/vue_shared/license_management/components/add_license_form_dropdown.vue';
import { KNOWN_LICENSES } from 'ee/vue_shared/license_management/constants';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AddLicenseFormDropdown', () => {
  const Component = Vue.extend(Dropdown);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('emits `input` invent on change', () => {
    vm = mountComponent(Component);
    spyOn(vm, '$emit');

    $(vm.$el)
      .val('LGPL')
      .trigger('change');
    expect(vm.$emit).toHaveBeenCalledWith('input', 'LGPL');
  });

  it('sets the placeholder appropriately', () => {
    const placeholder = 'Select a license';
    vm = mountComponent(Component, { placeholder });

    const dropdownContainer = $(vm.$el).select2('container')[0];

    expect(dropdownContainer.textContent).toContain(placeholder);
  });

  it('sets the initial value correctly', () => {
    const value = 'AWESOME_LICENSE';
    vm = mountComponent(Component, { value });

    expect(vm.$el.value).toContain(value);
  });

  it('shows all pre-defined licenses', done => {
    vm = mountComponent(Component);

    const element = $(vm.$el);

    element.on('select2-open', () => {
      const options = $('.select2-drop .select2-result');
      expect(KNOWN_LICENSES.length).toEqual(options.length);
      options.each(function() {
        expect(KNOWN_LICENSES).toContain($(this).text());
      });
      done();
    });

    element.select2('open');
  });
});
