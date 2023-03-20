import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormGroup, GlFormSelect, GlFormCheckbox } from '@gitlab/ui';
import ServiceAccountsForm from '~/google_cloud/service_accounts/form.vue';

describe('google_cloud/service_accounts/form', () => {
  let wrapper;

  const findHeader = () => wrapper.find('header');
  const findAllFormGroups = () => wrapper.findAllComponents(GlFormGroup);
  const findAllFormSelects = () => wrapper.findAllComponents(GlFormSelect);
  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const propsData = { gcpProjects: [], refs: [], cancelPath: '#cancel-url' };

  beforeEach(() => {
    wrapper = shallowMount(ServiceAccountsForm, { propsData, stubs: { GlFormCheckbox } });
  });

  it('contains header', () => {
    expect(findHeader().exists()).toBe(true);
  });

  it('contains GCP project form group', () => {
    const formGroup = findAllFormGroups().at(0);
    expect(formGroup.exists()).toBe(true);
  });

  it('contains GCP project dropdown', () => {
    const select = findAllFormSelects().at(0);
    expect(select.exists()).toBe(true);
  });

  it('contains Environments form group', () => {
    const formGroup = findAllFormGroups().at(1);
    expect(formGroup.exists()).toBe(true);
  });

  it('contains Environments dropdown', () => {
    const select = findAllFormSelects().at(1);
    expect(select.exists()).toBe(true);
  });

  it('contains Submit button', () => {
    const button = findAllButtons().at(0);
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe(ServiceAccountsForm.i18n.submitLabel);
  });

  it('contains Cancel button', () => {
    const button = findAllButtons().at(1);
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe(ServiceAccountsForm.i18n.cancelLabel);
    expect(button.attributes('href')).toBe('#cancel-url');
  });

  it('contains Confirmation checkbox', () => {
    const checkbox = findCheckbox();
    expect(checkbox.text()).toBe(ServiceAccountsForm.i18n.checkboxLabel);
  });

  it('checkbox must be required', () => {
    const checkbox = findCheckbox();
    expect(checkbox.attributes('required')).toBe('true');
  });
});
