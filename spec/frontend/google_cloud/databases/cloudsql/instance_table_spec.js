import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlTable } from '@gitlab/ui';
import InstanceTable from '~/google_cloud/databases/cloudsql/instance_table.vue';

describe('google_cloud/databases/cloudsql/instance_table', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTable = () => wrapper.findComponent(GlTable);

  describe('when there are no instances', () => {
    beforeEach(() => {
      const propsData = {
        cloudsqlInstances: [],
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = shallowMount(InstanceTable, { propsData });
    });

    it('should depict empty state', () => {
      const emptyState = findEmptyState();
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.attributes('title')).toBe(InstanceTable.i18n.noInstancesTitle);
      expect(emptyState.attributes('description')).toBe(InstanceTable.i18n.noInstancesDescription);
    });
  });

  describe('when there are three instances', () => {
    beforeEach(() => {
      const propsData = {
        cloudsqlInstances: [
          {
            ref: '*',
            gcp_project: 'test-gcp-project',
            instance_name: 'postgres-14-instance',
            version: 'POSTGRES_14',
          },
          {
            ref: 'production',
            gcp_project: 'prod-gcp-project',
            instance_name: 'postgres-14-instance',
            version: 'POSTGRES_14',
          },
          {
            ref: 'staging',
            gcp_project: 'test-gcp-project',
            instance_name: 'postgres-14-instance',
            version: 'POSTGRES_14',
          },
        ],
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = shallowMount(InstanceTable, { propsData });
    });

    it('should contain a table', () => {
      const table = findTable();
      expect(table.exists()).toBe(true);
    });
  });
});
