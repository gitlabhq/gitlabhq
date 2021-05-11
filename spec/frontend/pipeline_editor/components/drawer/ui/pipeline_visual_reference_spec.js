import { shallowMount } from '@vue/test-utils';
import DemoJobPill from '~/pipeline_editor/components/drawer/ui/demo_job_pill.vue';
import PipelineVisualReference from '~/pipeline_editor/components/drawer/ui/pipeline_visual_reference.vue';

describe('Demo job pill', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineVisualReference);
  };

  const findAllDemoJobPills = () => wrapper.findAllComponents(DemoJobPill);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders all stage names', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.stageNames.build);
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.stageNames.test);
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.stageNames.deploy);
  });

  it('renders all job pills', () => {
    expect(findAllDemoJobPills()).toHaveLength(4);
  });
});
