import { shallowMount } from '@vue/test-utils';

import timezoneMock from 'timezone-mock';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Time ago with tooltip component', () => {
  let vm;

  const timestamp = '2017-05-08T14:57:39.781Z';
  const timeAgoTimestamp = getTimeago().format(timestamp);

  const defaultProps = {
    time: timestamp,
  };

  const buildVm = (props = {}, scopedSlots = {}) => {
    vm = shallowMount(TimeAgoTooltip, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      scopedSlots,
    });
  };

  afterEach(() => {
    vm.destroy();
    timezoneMock.unregister();
  });

  it('should render timeago with a bootstrap tooltip', () => {
    buildVm();

    expect(vm.attributes('title')).toEqual(formatDate(timestamp));
    expect(vm.text()).toEqual(timeAgoTimestamp);
  });

  it('should render provided html class', () => {
    buildVm({
      cssClass: 'foo',
    });

    expect(vm.classes()).toContain('foo');
  });

  it('should render with the datetime attribute', () => {
    buildVm();

    expect(vm.attributes('datetime')).toEqual(timestamp);
  });

  it('should render provided scope content with the correct timeAgo string', () => {
    buildVm(null, { default: `<span>The time is {{ props.timeAgo }}</span>` });

    expect(vm.text()).toEqual(`The time is ${timeAgoTimestamp}`);
  });

  describe('number based timestamps', () => {
    // Store a date object before we mock the TZ
    const date = new Date();

    describe('with default TZ', () => {
      beforeEach(() => {
        buildVm({ time: date.getTime() });
      });

      it('handled correctly', () => {
        expect(vm.text()).toEqual(getTimeago().format(date.getTime()));
      });
    });

    describe.each`
      timezone           | offset
      ${'US/Pacific'}    | ${420}
      ${'US/Eastern'}    | ${240}
      ${'Brazil/East'}   | ${180}
      ${'UTC'}           | ${-0}
      ${'Europe/London'} | ${-60}
    `('with different client vs server TZ', ({ timezone, offset }) => {
      let tzDate;

      beforeEach(() => {
        timezoneMock.register(timezone);
        // Date object with mocked TZ
        tzDate = new Date();
        buildVm({ time: date.getTime() });
      });

      it('the date object should have correct timezones', () => {
        expect(tzDate.getTimezoneOffset()).toBe(offset);
      });

      it('timeago should handled the date correctly', () => {
        // getTime() should always handle the TZ, which allows for us to validate the date objects represent
        // the same date and time regardless of the TZ.
        expect(vm.text()).toEqual(getTimeago().format(date.getTime()));
        expect(vm.text()).toEqual(getTimeago().format(tzDate.getTime()));
      });
    });
  });
});
