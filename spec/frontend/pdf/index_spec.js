import { shallowMount } from '@vue/test-utils';
import { GlobalWorkerOptions } from 'pdfjs-dist/legacy/build/pdf';
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

    it('gets worker file path from environment var', () => {
      expect(GlobalWorkerOptions).toEqual({
        workerPort: null,
        workerSrc: 'mock/path/pdf.worker.js',
      });
    });
  });
});
