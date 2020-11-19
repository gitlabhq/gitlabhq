import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import stackedProgressBarComponent from '~/vue_shared/components/stacked_progress_bar.vue';

const createComponent = config => {
  const Component = Vue.extend(stackedProgressBarComponent);
  const defaultConfig = {
    successLabel: 'Synced',
    failureLabel: 'Failed',
    neutralLabel: 'Out of sync',
    successCount: 25,
    failureCount: 10,
    totalCount: 5000,
    ...config,
  };

  return mountComponent(Component, defaultConfig);
};

describe('StackedProgressBarComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  const findSuccessBarText = wrapper => wrapper.$el.querySelector('.status-green').innerText.trim();
  const findNeutralBarText = wrapper =>
    wrapper.$el.querySelector('.status-neutral').innerText.trim();
  const findFailureBarText = wrapper => wrapper.$el.querySelector('.status-red').innerText.trim();
  const findUnavailableBarText = wrapper =>
    wrapper.$el.querySelector('.status-unavailable').innerText.trim();

  describe('computed', () => {
    describe('neutralCount', () => {
      it('returns neutralCount based on totalCount, successCount and failureCount', () => {
        expect(vm.neutralCount).toBe(4965); // 5000 - 25 - 10
      });
    });
  });

  describe('template', () => {
    it('renders container element', () => {
      expect(vm.$el.classList.contains('stacked-progress-bar')).toBeTruthy();
    });

    it('renders empty state when count is unavailable', () => {
      const vmX = createComponent({ totalCount: 0, successCount: 0, failureCount: 0 });

      expect(findUnavailableBarText(vmX)).not.toBeUndefined();
    });

    it('renders bar elements when count is available', () => {
      expect(findSuccessBarText(vm)).not.toBeUndefined();
      expect(findNeutralBarText(vm)).not.toBeUndefined();
      expect(findFailureBarText(vm)).not.toBeUndefined();
    });

    describe('getPercent', () => {
      it('returns correct percentages from provided count based on `totalCount`', () => {
        vm = createComponent({ totalCount: 100, successCount: 25, failureCount: 10 });

        expect(findSuccessBarText(vm)).toBe('25%');
        expect(findNeutralBarText(vm)).toBe('65%');
        expect(findFailureBarText(vm)).toBe('10%');
      });

      it('returns percentage with decimal place when decimal is greater than 1', () => {
        vm = createComponent({ successCount: 67 });

        expect(findSuccessBarText(vm)).toBe('1.3%');
      });

      it('returns percentage as `< 1%` from provided count based on `totalCount` when evaluated value is less than 1', () => {
        vm = createComponent({ successCount: 10 });

        expect(findSuccessBarText(vm)).toBe('< 1%');
      });

      it('returns not available if totalCount is falsy', () => {
        vm = createComponent({ totalCount: 0 });

        expect(findUnavailableBarText(vm)).toBe('Not available');
      });

      it('returns 99.9% when numbers are extreme decimals', () => {
        vm = createComponent({ totalCount: 1000000 });

        expect(findNeutralBarText(vm)).toBe('99.9%');
      });
    });

    describe('barStyle', () => {
      it('returns style string based on percentage provided', () => {
        expect(vm.barStyle(50)).toBe('width: 50%;');
      });
    });

    describe('getTooltip', () => {
      describe('when hideTooltips is false', () => {
        it('returns label string based on label and count provided', () => {
          expect(vm.getTooltip('Synced', 10)).toBe('Synced: 10');
        });
      });

      describe('when hideTooltips is true', () => {
        beforeEach(() => {
          vm = createComponent({ hideTooltips: true });
        });

        it('returns an empty string', () => {
          expect(vm.getTooltip('Synced', 10)).toBe('');
        });
      });
    });
  });
});
