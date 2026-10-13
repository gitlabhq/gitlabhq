import { shallowMount } from '@vue/test-utils';
import CreditsPresenter from '~/glql/components/presenters/credits.vue';

describe('CreditsPresenter', () => {
  let wrapper;

  const createComponent = (data) => {
    wrapper = shallowMount(CreditsPresenter, {
      propsData: { data },
    });
  };

  it.each`
    data                  | expected
    ${0}                  | ${'0'}
    ${0.25}               | ${'0.25'}
    ${18.456416666666666} | ${'18.46'}
    ${41.5}               | ${'41.5'}
    ${2214.77}            | ${'2,214.77'}
  `('formats $data as $expected', ({ data, expected }) => {
    createComponent(data);
    expect(wrapper.text()).toBe(expected);
  });
});
