import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DurationPresenter from '~/glql/components/presenters/duration.vue';

describe('DurationPresenter', () => {
  it.each`
    seconds | expected
    ${60}   | ${'1m'}
    ${3600} | ${'1h'}
    ${3661} | ${'1h 1m 1s'}
    ${90}   | ${'1m 30s'}
    ${0}    | ${'0s'}
  `('renders $seconds seconds as "$expected"', ({ seconds, expected }) => {
    const wrapper = shallowMountExtended(DurationPresenter, { propsData: { data: seconds } });

    expect(wrapper.text()).toBe(expected);
  });
});
