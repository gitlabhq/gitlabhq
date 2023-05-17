import { mount } from '@vue/test-utils';
import { GlButton, GlTable } from '@gitlab/ui';
import DeploymentsServiceTable from '~/google_cloud/deployments/service_table.vue';

describe('google_cloud/deployments/service_table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findButtons = () => findTable().findAllComponents(GlButton);
  const findCloudRunButton = () => findButtons().at(0);
  const findCloudStorageButton = () => findButtons().at(1);

  beforeEach(() => {
    const propsData = {
      cloudRunUrl: '#url-enable-cloud-run',
      cloudStorageUrl: '#url-enable-cloud-storage',
    };
    wrapper = mount(DeploymentsServiceTable, { propsData });
  });

  it('should contain a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('should contain configure cloud run button', () => {
    const cloudRunButton = findCloudRunButton();
    expect(cloudRunButton.exists()).toBe(true);
    expect(cloudRunButton.attributes('href')).toBe('#url-enable-cloud-run');
  });

  it('should contain configure cloud storage button', () => {
    const cloudStorageButton = findCloudStorageButton();
    expect(cloudStorageButton.exists()).toBe(true);
    expect(cloudStorageButton.props().disabled).toBe(true);
    expect(cloudStorageButton.attributes('href')).toBe('#url-enable-cloud-storage');
  });
});
