import { mountExtended } from 'helpers/vue_test_utils_helper';
import TimePresenter from '~/glql/components/presenters/time.vue';

describe('TimePresenter', () => {
  beforeEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: false }).setSystemTime(new Date('2021-06-15'));
  });

  it.each`
    time                      | presentedAs
    ${'2021-06-13T00:00:00Z'} | ${'2 days ago'}
    ${'2021-06-17T00:00:00Z'} | ${'in 2 days'}
  `('for time $time, it presents it as "$presentedAs"', ({ time, presentedAs }) => {
    const wrapper = mountExtended(TimePresenter, { propsData: { data: time } });

    expect(wrapper.text()).toBe(presentedAs);
  });
});
