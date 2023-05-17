import { shallowMount } from '@vue/test-utils';
import DemoJobPill from '~/ci/pipeline_editor/components/drawer/ui/demo_job_pill.vue';

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

  it('renders the jobName', () => {
    expect(wrapper.text()).toContain(jobName);
  });
});
