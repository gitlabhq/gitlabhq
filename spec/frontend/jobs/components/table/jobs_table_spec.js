import { GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import { mockJobsInTable } from '../../mock_data';

describe('Jobs Table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(JobsTable, {
      propsData: {
        jobs: mockJobsInTable,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a table', () => {
    expect(findTable().exists()).toBe(true);
  });
});
