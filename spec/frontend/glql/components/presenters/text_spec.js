import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TextPresenter from '~/glql/components/presenters/text.vue';

describe('TextPresenter', () => {
  it.each`
    dataType    | data
    ${'String'} | ${'Hello, world!'}
    ${'Number'} | ${100}
  `('for data type $dataType, it renders the text', ({ data }) => {
    const wrapper = shallowMountExtended(TextPresenter, { propsData: { data } });

    expect(wrapper.text()).toBe(data.toString());
  });
});
