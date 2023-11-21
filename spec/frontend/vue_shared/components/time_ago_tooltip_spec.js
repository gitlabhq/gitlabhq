import { shallowMount } from '@vue/test-utils';
import { GlTruncate } from '@gitlab/ui';

import timezoneMock from 'timezone-mock';
import { getTimeago } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { DATE_ONLY_FORMAT } from '~/lib/utils/datetime/locale_dateformat';

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
    timezoneMock.unregister();
  });

  it('should render timeago with a bootstrap tooltip', () => {
    buildVm();

    expect(vm.attributes('title')).toEqual('May 8, 2017 at 2:57:39 PM GMT');
    expect(vm.text()).toEqual(timeAgoTimestamp);
  });

  it('should render truncated value with gl-truncate as true', () => {
    buildVm({
      enableTruncation: true,
    });

    expect(vm.findComponent(GlTruncate).exists()).toBe(true);
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

  it('should render with the timestamp provided as Date', () => {
    buildVm({ time: new Date(timestamp) });

    expect(vm.text()).toEqual(timeAgoTimestamp);
  });

  it('should render provided scope content with the correct timeAgo string', () => {
    buildVm(null, { default: `<span>The time is {{ props.timeAgo }}</span>` });

    expect(vm.text()).toEqual(`The time is ${timeAgoTimestamp}`);
  });

  describe('with User Setting timeDisplayRelative: false', () => {
    beforeEach(() => {
      window.gon = { time_display_relative: false };
    });

    it('should render with the correct absolute datetime in the default format', () => {
      buildVm();

      expect(vm.text()).toEqual('May 8, 2017, 2:57 PM');
    });

    it('should render with the correct absolute datetime in the requested dateTimeFormat', () => {
      buildVm({ dateTimeFormat: DATE_ONLY_FORMAT });

      expect(vm.text()).toEqual('May 8, 2017');
    });
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
