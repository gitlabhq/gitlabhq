import { shallowMount } from '@vue/test-utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';

describe('Time ago with tooltip component', () => {
  let vm;

  const buildVm = (propsData = {}) => {
    vm = shallowMount(TimeAgoTooltip, {
      attachToDocument: true,
      sync: false,
      propsData,
    });
  };
  const timestamp = '2017-05-08T14:57:39.781Z';

  afterEach(() => {
    vm.destroy();
  });

  it('should render timeago with a bootstrap tooltip', () => {
    buildVm({
      time: timestamp,
    });
    const timeago = getTimeago();

    expect(vm.attributes('title')).toEqual(formatDate(timestamp));
    expect(vm.text()).toEqual(timeago.format(timestamp));
  });

  it('should render provided html class', () => {
    buildVm({
      time: timestamp,
      cssClass: 'foo',
    });

    expect(vm.classes()).toContain('foo');
  });
});
