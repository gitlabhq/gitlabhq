import Vue from 'vue';

import WeeksHeaderItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_item.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeWeeks, mockShellWidth, mockItemWidth } from 'ee_spec/roadmap/mock_data';

const mockTimeframeIndex = 0;

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeWeeks[mockTimeframeIndex],
  timeframe = mockTimeframeWeeks,
  shellWidth = mockShellWidth,
  itemWidth = mockItemWidth,
}) => {
  const Component = Vue.extend(WeeksHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
    shellWidth,
    itemWidth,
  });
};

describe('WeeksHeaderItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();
      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
      expect(vm.lastDayOfCurrentWeek.getDate()).toBe(
        mockTimeframeWeeks[mockTimeframeIndex].getDate() + 7,
      );
    });
  });

  describe('computed', () => {
    describe('itemStyles', () => {
      it('returns style object for container element based on value of `itemWidth` prop', () => {
        vm = createComponent({});
        expect(vm.itemStyles.width).toBe('180px');
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year, Month and Date for current timeline header item', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderLabel).toBe('2017 Dec 24');
      });

      it('returns string containing only Month and Date for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 1,
          timeframeItem: mockTimeframeWeeks[mockTimeframeIndex + 1],
        });
        expect(vm.timelineHeaderLabel).toBe('Dec 31');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem week is less than current week', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current week is same as timeframeItem week', () => {
        vm = createComponent({});
        vm.currentDate = mockTimeframeWeeks[mockTimeframeIndex];
        expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
      });

      it('returns string containing `label-dark` when current week is less than timeframeItem week', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeWeeks[timeframeIndex];
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        [vm.currentDate] = mockTimeframeWeeks;
        expect(vm.timelineHeaderClass).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `timeline-header-item`', () => {
      expect(vm.$el.classList.contains('timeline-header-item')).toBeTruthy();
    });

    it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
      const itemLabelEl = vm.$el.querySelector('.item-label');
      expect(itemLabelEl).not.toBeNull();
      expect(itemLabelEl.innerText.trim()).toBe('2017 Dec 24');
    });
  });
});
