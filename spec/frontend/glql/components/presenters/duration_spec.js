import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DurationPresenter from '~/glql/components/presenters/duration.vue';

describe('DurationPresenter', () => {
  it.each`
    seconds | expected
    ${60}   | ${'1 minute'}
    ${3600} | ${'1 hour'}
    ${3661} | ${'1 hour 1 minute 1 second'}
    ${90}   | ${'1 minute 30 seconds'}
    ${0}    | ${'0 seconds'}
  `('renders $seconds seconds as "$expected"', ({ seconds, expected }) => {
    const wrapper = shallowMountExtended(DurationPresenter, { propsData: { data: seconds } });

    expect(wrapper.text()).toBe(expected);
  });
});
