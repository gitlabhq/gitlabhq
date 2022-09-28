import { shallowMount } from '@vue/test-utils';
import PipelineSchedules from '~/pipeline_schedules/components/pipeline_schedules.vue';
import PipelineSchedulesTable from '~/pipeline_schedules/components/table/pipeline_schedules_table.vue';

describe('Pipeline schedules app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineSchedules);
  };

  const findTable = () => wrapper.findComponent(PipelineSchedulesTable);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays table', () => {
    expect(findTable().exists()).toBe(true);
  });
});
