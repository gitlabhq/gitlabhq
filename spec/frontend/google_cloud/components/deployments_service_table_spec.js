import { mount } from '@vue/test-utils';
import { GlButton, GlTable } from '@gitlab/ui';
import DeploymentsServiceTable from '~/google_cloud/components/deployments_service_table.vue';

describe('google_cloud DeploymentsServiceTable component', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findButtons = () => findTable().findAllComponents(GlButton);
  const findCloudRunButton = () => findButtons().at(0);
  const findCloudStorageButton = () => findButtons().at(1);

  beforeEach(() => {
    const propsData = {
      cloudRunUrl: '#url-deployments-cloud-run',
      cloudStorageUrl: '#url-deployments-cloud-storage',
    };
    wrapper = mount(DeploymentsServiceTable, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should contain a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('should contain configure cloud run button', () => {
    const cloudRunButton = findCloudRunButton();
    expect(cloudRunButton.exists()).toBe(true);
    expect(cloudRunButton.props().disabled).toBe(true);
  });

  it('should contain configure cloud storage button', () => {
    const cloudStorageButton = findCloudStorageButton();
    expect(cloudStorageButton.exists()).toBe(true);
    expect(cloudStorageButton.props().disabled).toBe(true);
  });
});
