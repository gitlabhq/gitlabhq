import Vue from 'vue';

import QuartersHeaderItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_item.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeQuarters, mockShellWidth, mockItemWidth } from 'ee_spec/roadmap/mock_data';

const mockTimeframeIndex = 0;

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeQuarters[mockTimeframeIndex],
  timeframe = mockTimeframeQuarters,
  shellWidth = mockShellWidth,
  itemWidth = mockItemWidth,
}) => {
  const Component = Vue.extend(QuartersHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
    shellWidth,
    itemWidth,
  });
};

describe('QuartersHeaderItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();
      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
      expect(vm.quarterBeginDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[0]);
      expect(vm.quarterEndDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[2]);
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
      it('returns string containing Year and Quarter for current timeline header item', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderLabel).toBe('2017 Q4');
      });

      it('returns string containing only Quarter for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 2,
          timeframeItem: mockTimeframeQuarters[mockTimeframeIndex + 2],
        });
        expect(vm.timelineHeaderLabel).toBe('Q2');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem quarter is less than current quarter', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current quarter is same as timeframeItem quarter', done => {
        vm = createComponent({
          timeframeItem: mockTimeframeQuarters[1],
        });

        [, vm.currentDate] = mockTimeframeQuarters[1].range;
        Vue.nextTick()
          .then(() => {
            expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns string containing `label-dark` when current quarter is less than timeframeItem quarter', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeQuarters[1];
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        [vm.currentDate] = mockTimeframeQuarters[0].range;
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
      expect(itemLabelEl.innerText.trim()).toBe('2017 Q4');
    });
  });
});
