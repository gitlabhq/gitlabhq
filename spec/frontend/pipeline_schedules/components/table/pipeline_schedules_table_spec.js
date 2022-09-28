import { shallowMount } from '@vue/test-utils';
import { GlTableLite } from '@gitlab/ui';
import PipelineSchedulesTable from '~/pipeline_schedules/components/table/pipeline_schedules_table.vue';

describe('Pipeline schedules table', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineSchedulesTable);
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

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
