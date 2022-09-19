import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineFailed from '~/vue_merge_request_widget/components/states/pipeline_failed.vue';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

describe('PipelineFailed', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineFailed, {
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render error status icon', () => {
    expect(wrapper.findComponent(StatusIcon).exists()).toBe(true);
    expect(wrapper.findComponent(StatusIcon).props().status).toBe('failed');
  });

  it('should render error message with a disabled merge button', () => {
    expect(wrapper.text()).toContain('Merge blocked: pipeline must succeed.');
    expect(wrapper.text()).toContain('Push a commit that fixes the failure');
    expect(wrapper.findComponent(GlLink).text()).toContain('learn about other solutions');
  });
});
