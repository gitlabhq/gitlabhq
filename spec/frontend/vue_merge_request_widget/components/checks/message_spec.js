import { mountExtended } from 'helpers/vue_test_utils_helper';
import MessageComponent from '~/vue_merge_request_widget/components/checks/message.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = mountExtended(MessageComponent, {
    propsData,
  });
}

describe('Merge request merge checks message component', () => {
  it('renders failure reason text', () => {
    factory({ check: { result: 'passed', identifier: 'discussions_not_resolved' } });

    expect(wrapper.text()).toEqual('Unresolved discussions must be resolved.');
  });

  it.each`
    result               | icon
    ${'passed'}          | ${'success'}
    ${'failed'}          | ${'failed'}
    ${'allowed_to_fail'} | ${'neutral'}
  `('renders $icon icon for $result result', ({ result, icon }) => {
    factory({ check: { result } });

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(icon);
  });
});
