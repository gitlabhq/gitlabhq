import { shallowMount } from '@vue/test-utils';
import PipelineBlockedComponent from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_blocked.vue';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

describe('MRWidgetPipelineBlocked', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(PipelineBlockedComponent);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders error icon', () => {
    expect(wrapper.findComponent(StatusIcon).exists()).toBe(true);
    expect(wrapper.findComponent(StatusIcon).props().status).toBe('failed');
  });

  it('renders information text', () => {
    expect(wrapper.text()).toBe(
      "Merge blocked: pipeline must succeed. It's waiting for a manual action to continue.",
    );
  });
});
