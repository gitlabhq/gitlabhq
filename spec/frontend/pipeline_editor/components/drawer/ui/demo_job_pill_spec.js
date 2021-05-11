import { shallowMount } from '@vue/test-utils';
import DemoJobPill from '~/pipeline_editor/components/drawer/ui/demo_job_pill.vue';

describe('Demo job pill', () => {
  let wrapper;
  const jobName = 'my-build-job';

  const createComponent = () => {
    wrapper = shallowMount(DemoJobPill, {
      propsData: {
        jobName,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the jobName', () => {
    expect(wrapper.text()).toContain(jobName);
  });
});
