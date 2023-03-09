import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import GcpRegionsForm from '~/google_cloud/gcp_regions/form.vue';

describe('google_cloud/gcp_regions/form', () => {
  let wrapper;

  const findHeader = () => wrapper.find('header');
  const findAllFormGroups = () => wrapper.findAllComponents(GlFormGroup);
  const findAllFormSelects = () => wrapper.findAllComponents(GlFormSelect);
  const findAllButtons = () => wrapper.findAllComponents(GlButton);

  const propsData = { availableRegions: [], refs: [], cancelPath: '#cancel-url' };

  beforeEach(() => {
    wrapper = shallowMount(GcpRegionsForm, { propsData });
  });

  it('contains header', () => {
    expect(findHeader().exists()).toBe(true);
  });

  it('contains Regions form group', () => {
    const formGroup = findAllFormGroups().at(0);
    expect(formGroup.exists()).toBe(true);
  });

  it('contains Regions dropdown', () => {
    const select = findAllFormSelects().at(0);
    expect(select.exists()).toBe(true);
  });

  it('contains Refs form group', () => {
    const formGroup = findAllFormGroups().at(1);
    expect(formGroup.exists()).toBe(true);
  });

  it('contains Refs dropdown', () => {
    const select = findAllFormSelects().at(1);
    expect(select.exists()).toBe(true);
  });

  it('contains Submit button', () => {
    const button = findAllButtons().at(0);
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe(GcpRegionsForm.i18n.submitLabel);
  });

  it('contains Cancel button', () => {
    const button = findAllButtons().at(1);
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe(GcpRegionsForm.i18n.cancelLabel);
    expect(button.attributes('href')).toBe('#cancel-url');
  });
});
