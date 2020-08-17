import { shallowMount } from '@vue/test-utils';

import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Time ago with tooltip component', () => {
  let vm;

  const buildVm = (propsData = {}, scopedSlots = {}) => {
    vm = shallowMount(TimeAgoTooltip, {
      propsData,
      scopedSlots,
    });
  };
  const timestamp = '2017-05-08T14:57:39.781Z';
  const timeAgoTimestamp = getTimeago().format(timestamp);

  afterEach(() => {
    vm.destroy();
  });

  it('should render timeago with a bootstrap tooltip', () => {
    buildVm({
      time: timestamp,
    });

    expect(vm.attributes('title')).toEqual(formatDate(timestamp));
    expect(vm.text()).toEqual(timeAgoTimestamp);
  });

  it('should render provided html class', () => {
    buildVm({
      time: timestamp,
      cssClass: 'foo',
    });

    expect(vm.classes()).toContain('foo');
  });

  it('should render with the datetime attribute', () => {
    buildVm({ time: timestamp });

    expect(vm.attributes('datetime')).toEqual(timestamp);
  });

  it('should render provided scope content with the correct timeAgo string', () => {
    buildVm({ time: timestamp }, { default: `<span>The time is {{ props.timeAgo }}</span>` });

    expect(vm.text()).toEqual(`The time is ${timeAgoTimestamp}`);
  });
});
