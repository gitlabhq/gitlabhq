import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Panel from '~/google_cloud/deployments/panel.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import GoogleCloudMenu from '~/google_cloud/components/google_cloud_menu.vue';
import ServiceTable from '~/google_cloud/deployments/service_table.vue';

describe('google_cloud/deployments/panel', () => {
  let wrapper;

  const props = {
    configurationUrl: 'configuration-url',
    deploymentsUrl: 'deployments-url',
    databasesUrl: 'databases-url',
    enableCloudRunUrl: 'cloud-run-url',
    enableCloudStorageUrl: 'cloud-storage-url',
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(Panel, { propsData: props });
  });

  it('contains incubation banner', () => {
    const target = wrapper.findComponent(IncubationBanner);
    expect(target.exists()).toBe(true);
  });

  it('contains google cloud menu with `deployments` active', () => {
    const target = wrapper.findComponent(GoogleCloudMenu);
    expect(target.exists()).toBe(true);
    expect(target.props('active')).toBe('deployments');
    expect(target.props('configurationUrl')).toBe(props.configurationUrl);
    expect(target.props('deploymentsUrl')).toBe(props.deploymentsUrl);
    expect(target.props('databasesUrl')).toBe(props.databasesUrl);
  });

  it('contains service-table', () => {
    const target = wrapper.findComponent(ServiceTable);
    expect(target.exists()).toBe(true);
    expect(target.props('cloudRunUrl')).toBe(props.enableCloudRunUrl);
    expect(target.props('cloudStorageUrl')).toBe(props.enableCloudStorageUrl);
  });
});
