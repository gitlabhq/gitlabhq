import { shallowMount } from '@vue/test-utils';
import PercentagePresenter from '~/glql/components/presenters/percentage.vue';

describe('PercentagePresenter', () => {
  let wrapper;

  const createComponent = (data) => {
    wrapper = shallowMount(PercentagePresenter, {
      propsData: { data },
    });
  };

  it.each`
    data      | expected
    ${0.425}  | ${'42.5%'}
    ${0}      | ${'0%'}
    ${1}      | ${'100%'}
    ${0.001}  | ${'0.1%'}
    ${0.9875} | ${'98.8%'}
  `('formats $data as $expected', ({ data, expected }) => {
    createComponent(data);
    expect(wrapper.text()).toBe(expected);
  });
});
