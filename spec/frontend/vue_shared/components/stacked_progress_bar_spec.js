import { mount } from '@vue/test-utils';
import StackedProgressBarComponent from '~/vue_shared/components/stacked_progress_bar.vue';

describe('StackedProgressBarComponent', () => {
  let wrapper;

  const createComponent = (config) => {
    const defaultConfig = {
      successLabel: 'Synced',
      failureLabel: 'Failed',
      neutralLabel: 'Out of sync',
      successCount: 25,
      failureCount: 10,
      totalCount: 5000,
      ...config,
    };

    wrapper = mount(StackedProgressBarComponent, { propsData: defaultConfig });
  };

  const findSuccessBar = () => wrapper.find('.status-green');
  const findNeutralBar = () => wrapper.find('.status-neutral');
  const findFailureBar = () => wrapper.find('.status-red');
  const findUnavailableBar = () => wrapper.find('.status-unavailable');

  describe('template', () => {
    it('renders container element', () => {
      createComponent();

      expect(wrapper.classes()).toContain('stacked-progress-bar');
    });

    it('renders empty state when count is unavailable', () => {
      createComponent({ totalCount: 0, successCount: 0, failureCount: 0 });

      expect(findUnavailableBar()).not.toBeUndefined();
    });

    it('renders bar elements when count is available', () => {
      createComponent();

      expect(findSuccessBar().exists()).toBe(true);
      expect(findNeutralBar().exists()).toBe(true);
      expect(findFailureBar().exists()).toBe(true);
    });

    describe('getPercent', () => {
      it('returns correct percentages from provided count based on `totalCount`', () => {
        createComponent({ totalCount: 100, successCount: 25, failureCount: 10 });

        expect(findSuccessBar().text()).toBe('25%');
        expect(findNeutralBar().text()).toBe('65%');
        expect(findFailureBar().text()).toBe('10%');
      });

      it('returns percentage with decimal place when decimal is greater than 1', () => {
        createComponent({ successCount: 67 });

        expect(findSuccessBar().text()).toBe('1.3%');
      });

      it('returns percentage as `< 1%` from provided count based on `totalCount` when evaluated value is less than 1', () => {
        createComponent({ successCount: 10 });

        expect(findSuccessBar().text()).toBe('< 1%');
      });

      it('returns not available if totalCount is falsy', () => {
        createComponent({ totalCount: 0 });

        expect(findUnavailableBar().text()).toBe('Not available');
      });

      it('returns 99.9% when numbers are extreme decimals', () => {
        createComponent({ totalCount: 1000000 });

        expect(findNeutralBar().text()).toBe('99.9%');
      });
    });

    describe('bar style', () => {
      it('renders width based on percentage provided', () => {
        createComponent({ totalCount: 100, successCount: 25 });

        expect(findSuccessBar().element.style.width).toBe('25%');
      });
    });

    describe('tooltip', () => {
      describe('when hideTooltips is false', () => {
        it('returns label string based on label and count provided', () => {
          createComponent({ successCount: 10, successLabel: 'Synced', hideTooltips: false });

          expect(findSuccessBar().attributes('title')).toBe('Synced: 10');
        });
      });

      describe('when hideTooltips is true', () => {
        it('returns an empty string', () => {
          createComponent({ successCount: 10, successLabel: 'Synced', hideTooltips: true });

          expect(findSuccessBar().attributes('title')).toBe('');
        });
      });
    });
  });
});
