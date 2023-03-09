import { shallowMount } from '@vue/test-utils';
import notAllowedComponent from '~/vue_merge_request_widget/components/states/mr_widget_not_allowed.vue';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

describe('MRWidgetNotAllowed', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(notAllowedComponent);
  });

  it('renders success icon', () => {
    expect(wrapper.findComponent(StatusIcon).exists()).toBe(true);
    expect(wrapper.findComponent(StatusIcon).props().status).toBe('success');
  });

  it('renders informative text', () => {
    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain('Ready to be merged automatically.');
    expect(message).toContain(
      'Ask someone with write access to this repository to merge this request',
    );
  });
});
