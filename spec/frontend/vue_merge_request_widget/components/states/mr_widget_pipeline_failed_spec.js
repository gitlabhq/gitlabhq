import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { removeBreakLine } from 'helpers/text_helper';
import PipelineFailed from '~/vue_merge_request_widget/components/states/pipeline_failed.vue';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

describe('PipelineFailed', () => {
  let wrapper;

  const createComponent = (mr = {}) => {
    wrapper = shallowMount(PipelineFailed, {
      propsData: {
        mr,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('should render error status icon', () => {
    createComponent();

    expect(wrapper.findComponent(StatusIcon).exists()).toBe(true);
    expect(wrapper.findComponent(StatusIcon).props().status).toBe('failed');
  });

  it('should render error message with a disabled merge button', () => {
    createComponent();

    const text = removeBreakLine(wrapper.text()).trim();
    expect(text).toContain('Merge blocked:');
    expect(text).toContain('pipeline must succeed');
    expect(text).toContain('Push a commit that fixes the failure');
    expect(wrapper.findComponent(GlLink).text()).toContain('learn about other solutions');
  });

  it('should render pipeline blocked message', () => {
    createComponent({ isPipelineBlocked: true });

    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain('Merge blocked:');
    expect(message).toContain(
      "pipeline must succeed. It's waiting for a manual action to continue.",
    );
  });
});
