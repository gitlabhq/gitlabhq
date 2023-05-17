import { GlDaterangePicker } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import Daterange from '~/analytics/shared/components/daterange.vue';

const defaultProps = {
  startDate: new Date(2019, 8, 1),
  endDate: new Date(2019, 8, 11),
};

describe('Daterange component', () => {
  useFakeDate(2019, 8, 25);

  let wrapper;

  const factory = (props = defaultProps, mountFn = shallowMountExtended) => {
    wrapper = mountFn(Daterange, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findDaterangePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findDateRangeIndicator = () => wrapper.findByTestId('daterange-picker-indicator');

  describe('template', () => {
    describe('when show is false', () => {
      it('does not render the daterange picker', () => {
        factory({ show: false });
        expect(findDaterangePicker().exists()).toBe(false);
      });
    });

    describe('when show is true', () => {
      it('renders the daterange picker', () => {
        factory({ show: true });

        expect(findDaterangePicker().exists()).toBe(true);
      });
    });

    describe('with a minDate being set', () => {
      it('emits the change event with the minDate when the user enters a start date before the minDate', async () => {
        const startDate = new Date('2019-09-01');
        const endDate = new Date('2019-09-30');
        const minDate = new Date('2019-06-01');

        factory({ show: true, startDate, endDate, minDate }, mountExtended);
        const input = findDaterangePicker().find('input');

        input.setValue('2019-01-01');
        await input.trigger('change');

        expect(wrapper.emitted().change).toEqual([[{ startDate: minDate, endDate }]]);
      });
    });

    describe('with a maxDateRange being set', () => {
      beforeEach(() => {
        factory({ maxDateRange: 30 }, mountExtended);
      });

      it('displays the max date range indicator', () => {
        expect(findDateRangeIndicator().exists()).toBe(true);
      });

      it('displays the correct number of selected days in the indicator', () => {
        expect(findDateRangeIndicator().text()).toBe('10 days selected');
      });

      it('sets the tooltip', () => {
        const tooltip = findDaterangePicker().props('tooltip');
        expect(tooltip).toBe(
          'Showing data for workflow items completed in this date range. Date range limited to 30 days.',
        );
      });
    });
  });

  describe('computed', () => {
    describe('dateRange', () => {
      beforeEach(() => {
        factory({ show: true });
      });

      describe('set', () => {
        it('emits the change event with an object containing startDate and endDate', async () => {
          const startDate = new Date('2019-10-01');
          const endDate = new Date('2019-10-05');

          await findDaterangePicker().vm.$emit('input', { startDate, endDate });

          expect(wrapper.emitted('change')).toEqual([[{ startDate, endDate }]]);
        });
      });

      describe('get', () => {
        it("datepicker to have default of dateRange from state's startDate and endDate", () => {
          expect(findDaterangePicker().props('value')).toEqual({
            startDate: defaultProps.startDate,
            endDate: defaultProps.endDate,
          });
        });
      });
    });
  });
});
