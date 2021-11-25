import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import ServiceAccountsForm from '~/google_cloud/components/screens/service_accounts_form.vue';

describe('ServiceAccountsForm component', () => {
  let wrapper;

  const findIncubationBanner = () => wrapper.findComponent(IncubationBanner);
  const findHeader = () => wrapper.find('header');
  const findAllFormGroups = () => wrapper.findAllComponents(GlFormGroup);
  const findAllFormSelects = () => wrapper.findAllComponents(GlFormSelect);
  const findAllButtons = () => wrapper.findAllComponents(GlButton);

  const propsData = { gcpProjects: [], environments: [], cancelPath: '#cancel-url' };

  beforeEach(() => {
    wrapper = shallowMount(ServiceAccountsForm, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains incubation banner', () => {
    expect(findIncubationBanner().exists()).toBe(true);
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
    const formGorup = findAllFormGroups().at(1);
    expect(formGorup.exists()).toBe(true);
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
});
