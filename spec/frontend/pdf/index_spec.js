import { shallowMount } from '@vue/test-utils';
import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

describe('PDFLab component', () => {
  let wrapper;

  const mountComponent = ({ pdf }) => shallowMount(PDFLab, { propsData: { pdf } });

  describe('without PDF data', () => {
    beforeEach(() => {
      wrapper = mountComponent({ pdf: '' });
    });

    it('does not render', () => {
      expect(wrapper.isVisible()).toBe(false);
    });
  });

  describe('with PDF data', () => {
    beforeEach(() => {
      wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf` });
    });

    it('renders', () => {
      expect(wrapper.isVisible()).toBe(true);
    });
  });
});
