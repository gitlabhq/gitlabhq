import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeTimeComponent from '~/vue_merge_request_widget/components/checks/merge_time.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = mountExtended(MergeTimeComponent, {
    propsData,
  });
}

describe('Merge request merge checks merge time component', () => {
  it('renders failure reason text', () => {
    factory({
      check: { status: 'success', identifier: 'merge_time' },
      mr: { mergeAfter: '2024-10-17T18:23:00Z' },
    });

    expect(wrapper.text()).toBe('Cannot merge until Oct 17, 2024, 6:23 PM');
  });

  it.each`
    status        | icon
    ${'success'}  | ${'success'}
    ${'failed'}   | ${'failed'}
    ${'inactive'} | ${'neutral'}
  `('renders $icon icon for $status result', ({ status, icon }) => {
    factory({
      check: { status, identifier: 'merge_time' },
      mr: { mergeAfter: '2024-10-17T18:23:00Z' },
    });

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(icon);
  });
});
