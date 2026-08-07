import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DurationMsPresenter from '~/glql/components/presenters/duration_ms.vue';

describe('DurationMsPresenter', () => {
  it.each`
    milliseconds | expected
    ${60000}     | ${'1m'}
    ${3600000}   | ${'1h'}
    ${3661000}   | ${'1h 1m 1s'}
    ${250000}    | ${'4m 10s'}
    ${0}         | ${'0s'}
  `('renders $milliseconds milliseconds as "$expected"', ({ milliseconds, expected }) => {
    const wrapper = shallowMountExtended(DurationMsPresenter, {
      propsData: { data: milliseconds },
    });

    expect(wrapper.text()).toBe(expected);
  });
});
