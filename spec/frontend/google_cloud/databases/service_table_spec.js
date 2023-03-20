import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ServiceTable from '~/google_cloud/databases/service_table.vue';

describe('google_cloud/databases/service_table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);

  beforeEach(() => {
    const propsData = {
      cloudsqlPostgresUrl: '#url-cloudsql-postgres',
      cloudsqlMysqlUrl: '#url-cloudsql-mysql',
      cloudsqlSqlserverUrl: '#url-cloudsql-sqlserver',
      alloydbPostgresUrl: '#url-alloydb-postgres',
      memorystoreRedisUrl: '#url-memorystore-redis',
      firestoreUrl: '#url-firestore',
    };
    wrapper = mountExtended(ServiceTable, { propsData });
  });

  it('should contain a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it.each`
    name                    | testId                         | url
    ${'cloudsql-postgres'}  | ${'button-cloudsql-postgres'}  | ${'#url-cloudsql-postgres'}
    ${'cloudsql-mysql'}     | ${'button-cloudsql-mysql'}     | ${'#url-cloudsql-mysql'}
    ${'cloudsql-sqlserver'} | ${'button-cloudsql-sqlserver'} | ${'#url-cloudsql-sqlserver'}
    ${'alloydb-postgres'}   | ${'button-alloydb-postgres'}   | ${'#url-alloydb-postgres'}
    ${'memorystore-redis'}  | ${'button-memorystore-redis'}  | ${'#url-memorystore-redis'}
    ${'firestore'}          | ${'button-firestore'}          | ${'#url-firestore'}
  `('renders $name button with correct url', ({ testId, url }) => {
    const button = wrapper.findByTestId(testId);

    expect(button.exists()).toBe(true);
    expect(button.attributes('href')).toBe(url);
  });
});
