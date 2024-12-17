import { shallowMount } from '@vue/test-utils';
// eslint-disable-next-line import/extensions
import { GlobalWorkerOptions } from 'pdfjs-dist/legacy/build/pdf.mjs';
import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

describe('PDFLab component', () => {
  let wrapper;

  const mountComponent = ({ pdf }) =>
    shallowMount(PDFLab, {
      propsData: { pdf },
    });

  describe('without PDF data', () => {
    beforeEach(() => {
      wrapper = mountComponent({ pdf: '' });
    });

    it('does not render', () => {
      expect(wrapper.isVisible()).toBe(false);
    });
  });

  describe('with PDF data', () => {
    let mockGetDocument;
    beforeEach(async () => {
      mockGetDocument = jest.fn().mockReturnValue({ promise: Promise.resolve() });
      jest.mock('pdfjs-dist/legacy/build/pdf.mjs', () => ({
        ...jest.requireActual('pdfjs-dist/legacy/build/pdf.mjs'),
        getDocument: mockGetDocument,
      }));
      wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf` });
      await wrapper.vm.load();
    });

    it('renders with pdfjs-dist', () => {
      expect(mockGetDocument).toHaveBeenCalledWith({
        url: '/fixtures/blob/pdf/test.pdf',
        cMapUrl: process.env.PDF_JS_CMAPS_PUBLIC_PATH,
        cMapPacked: true,
        isEvalSupported: true,
      });
      expect(wrapper.isVisible()).toBe(true);
    });

    it('gets worker file path from environment var', () => {
      expect(GlobalWorkerOptions.workerSrc).toBe('mock/path/v4/pdf.worker.js');
    });
  });
});
