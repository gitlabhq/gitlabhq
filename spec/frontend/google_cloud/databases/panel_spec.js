import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Panel from '~/google_cloud/databases/panel.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import GoogleCloudMenu from '~/google_cloud/components/google_cloud_menu.vue';
import ServiceTable from '~/google_cloud/databases/service_table.vue';
import InstanceTable from '~/google_cloud/databases/cloudsql/instance_table.vue';

describe('google_cloud/databases/panel', () => {
  let wrapper;

  const props = {
    configurationUrl: 'configuration-url',
    deploymentsUrl: 'deployments-url',
    databasesUrl: 'databases-url',
    cloudsqlPostgresUrl: 'cloudsql-postgres-url',
    cloudsqlMysqlUrl: 'cloudsql-mysql-url',
    cloudsqlSqlserverUrl: 'cloudsql-sqlserver-url',
    cloudsqlInstances: [],
    emptyIllustrationUrl: 'empty-illustration-url',
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(Panel, { propsData: props });
  });

  it('contains incubation banner', () => {
    const target = wrapper.findComponent(IncubationBanner);
    expect(target.exists()).toBe(true);
  });

  it('contains google cloud menu with `databases` active', () => {
    const target = wrapper.findComponent(GoogleCloudMenu);
    expect(target.exists()).toBe(true);
    expect(target.props('active')).toBe('databases');
    expect(target.props('configurationUrl')).toBe(props.configurationUrl);
    expect(target.props('deploymentsUrl')).toBe(props.deploymentsUrl);
    expect(target.props('databasesUrl')).toBe(props.databasesUrl);
  });

  it('contains Databases service table', () => {
    const target = wrapper.findComponent(ServiceTable);
    expect(target.exists()).toBe(true);
  });

  it('contains CloudSQL instance table', () => {
    const target = wrapper.findComponent(InstanceTable);
    expect(target.exists()).toBe(true);
  });
});
