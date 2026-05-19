import { shallowMount } from '@vue/test-utils';
import NumberPresenter from '~/glql/components/presenters/number.vue';

describe('NumberPresenter', () => {
  let wrapper;

  const createComponent = (data) => {
    wrapper = shallowMount(NumberPresenter, {
      propsData: { data },
    });
  };

  it.each`
    description                                | input      | expected
    ${'formats large numbers with separators'} | ${1234567} | ${'1,234,567'}
    ${'handles zero'}                          | ${0}       | ${'0'}
    ${'formats small numbers'}                 | ${42}      | ${'42'}
    ${'formats thousands'}                     | ${1000}    | ${'1,000'}
    ${'formats millions'}                      | ${1000000} | ${'1,000,000'}
    ${'handles negative numbers'}              | ${-1234}   | ${'-1,234'}
  `('$description', ({ input, expected }) => {
    createComponent(input);
    expect(wrapper.text()).toBe(expected);
  });
});
