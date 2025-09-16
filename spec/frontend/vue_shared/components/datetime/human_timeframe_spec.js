import { shallowMount } from '@vue/test-utils';
import HumanTimeframe from '~/vue_shared/components/datetime/human_timeframe.vue';
import { humanTimeframe, newDate } from '~/lib/utils/datetime_utility';

describe('HumanTimeframe', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(HumanTimeframe, {
      propsData: props,
    });
  };

  describe('component rendering with different date scenarios', () => {
    describe.each`
      scenario                | from                      | till
      ${'default'}            | ${'2024-01-01T00:00:00Z'} | ${'2024-01-31T23:59:59Z'}
      ${'same month'}         | ${'2024-06-01T00:00:00Z'} | ${'2024-06-15T23:59:59Z'}
      ${'cross year'}         | ${'2023-12-15T00:00:00Z'} | ${'2024-02-28T23:59:59Z'}
      ${'only start date'}    | ${'2024-03-15T00:00:00Z'} | ${null}
      ${'only end date'}      | ${null}                   | ${'2024-12-25T23:59:59Z'}
      ${'single day'}         | ${'2024-07-04T00:00:00Z'} | ${'2024-07-04T23:59:59Z'}
      ${'using date objects'} | ${new Date(2024, 6, 4)}   | ${new Date(2025, 6, 7)}
      ${'empty dates'}        | ${null}                   | ${null}
      ${'empty strings'}      | ${''}                     | ${''}
    `('$scenario:', ({ from, till }) => {
      it('renders date range', () => {
        createComponent({ from, till });

        const expectedTimeframe = humanTimeframe(
          from ? newDate(from) : null,
          till ? newDate(till) : null,
        );

        expect(wrapper.text()).toBe(expectedTimeframe);
      });
    });
  });
});
