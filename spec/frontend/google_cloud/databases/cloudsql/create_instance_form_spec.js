import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InstanceForm from '~/google_cloud/databases/cloudsql/create_instance_form.vue';

describe('google_cloud/databases/cloudsql/create_instance_form', () => {
  let wrapper;

  const findByTestId = (id) => wrapper.findByTestId(id);
  const findCancelButton = () => findByTestId('cancel-button');
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findHeader = () => wrapper.find('header');
  const findSubmitButton = () => findByTestId('submit-button');

  const propsData = {
    gcpProjects: [],
    refs: [],
    cancelPath: '#cancel-url',
    formTitle: 'mock form title',
    formDescription: 'mock form description',
    databaseVersions: [],
    tiers: [],
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(InstanceForm, { propsData, stubs: { GlFormCheckbox } });
  });

  it('contains header', () => {
    expect(findHeader().exists()).toBe(true);
  });

  it('contains GCP project form group', () => {
    const formGroup = findByTestId('form_group_gcp_project');
    expect(formGroup.exists()).toBe(true);
    expect(formGroup.attributes('label')).toBe(InstanceForm.i18n.gcpProjectLabel);
    expect(formGroup.attributes('description')).toBe(InstanceForm.i18n.gcpProjectDescription);
  });

  it('contains GCP project dropdown', () => {
    const select = findByTestId('select_gcp_project');
    expect(select.exists()).toBe(true);
  });

  it('contains Environments form group', () => {
    const formGroup = findByTestId('form_group_environments');
    expect(formGroup.exists()).toBe(true);
    expect(formGroup.attributes('label')).toBe(InstanceForm.i18n.refsLabel);
    expect(formGroup.attributes('description')).toBe(InstanceForm.i18n.refsDescription);
  });

  it('contains Environments dropdown', () => {
    const select = findByTestId('select_environments');
    expect(select.exists()).toBe(true);
  });

  it('contains Tier form group', () => {
    const formGroup = findByTestId('form_group_tier');
    expect(formGroup.exists()).toBe(true);
    expect(formGroup.attributes('label')).toBe(InstanceForm.i18n.tierLabel);
    expect(formGroup.attributes('description')).toBe(InstanceForm.i18n.tierDescription);
  });

  it('contains Tier dropdown', () => {
    const select = findByTestId('select_tier');
    expect(select.exists()).toBe(true);
  });

  it('contains Database Version form group', () => {
    const formGroup = findByTestId('form_group_database_version');
    expect(formGroup.exists()).toBe(true);
    expect(formGroup.attributes('label')).toBe(InstanceForm.i18n.databaseVersionLabel);
  });

  it('contains Database Version dropdown', () => {
    const select = findByTestId('select_database_version');
    expect(select.exists()).toBe(true);
  });

  it('contains Submit button', () => {
    expect(findSubmitButton().exists()).toBe(true);
    expect(findSubmitButton().text()).toBe(InstanceForm.i18n.submitLabel);
  });

  it('contains Cancel button', () => {
    expect(findCancelButton().exists()).toBe(true);
    expect(findCancelButton().text()).toBe(InstanceForm.i18n.cancelLabel);
    expect(findCancelButton().attributes('href')).toBe('#cancel-url');
  });

  it('contains Confirmation checkbox', () => {
    const checkbox = findCheckbox();
    expect(checkbox.text()).toBe(InstanceForm.i18n.checkboxLabel);
  });

  it('checkbox must be required', () => {
    const checkbox = findCheckbox();
    expect(checkbox.attributes('required')).toBe('true');
  });
});
