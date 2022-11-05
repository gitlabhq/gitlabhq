import { shallowMount } from '@vue/test-utils';
import { GlForm } from '@gitlab/ui';
import PipelineSchedulesForm from '~/ci/pipeline_schedules/components/pipeline_schedules_form.vue';

describe('Pipeline schedules form', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineSchedulesForm);
  };

  const findForm = () => wrapper.findComponent(GlForm);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays form', () => {
    expect(findForm().exists()).toBe(true);
  });
});
