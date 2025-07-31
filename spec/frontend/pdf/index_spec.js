import { shallowMount } from '@vue/test-utils';
import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

const mockGetDocument = jest.fn();
const mockGlobalWorkerOptions = { workerSrc: '' };

jest.mock('pdfjs-dist/legacy/build/pdf.mjs', () => ({
  ...jest.requireActual('pdfjs-dist/legacy/build/pdf.mjs'),
  GlobalWorkerOptions: mockGlobalWorkerOptions,
  getDocument: mockGetDocument,
}));

describe('PDFLab component', () => {
  let wrapper;

  const mountComponent = ({ pdf }) =>
    shallowMount(PDFLab, {
      propsData: { pdf },
    });

  beforeEach(() => {
    mockGetDocument.mockReset();
    mockGetDocument.mockReturnValue({
      promise: Promise.resolve({
        numPages: 1,
        getPage: jest.fn().mockResolvedValue({}),
      }),
    });
    mockGlobalWorkerOptions.workerSrc = '';
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
    describe('when gon.relative_url_root is not set', () => {
      beforeEach(() => {
        window.gon = { relative_url_root: '' };
        wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf` });
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

      it('sets worker file path without relative URL root', () => {
        expect(mockGlobalWorkerOptions.workerSrc).toBe(process.env.PDF_JS_WORKER_PUBLIC_PATH);
      });
    });

    describe('when gon.relative_url_root is set', () => {
      beforeEach(() => {
        window.gon = { relative_url_root: '/gitlab' };
        wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf` });
      });

      it('renders with pdfjs-dist and includes relative URL root in cMapUrl', () => {
        expect(mockGetDocument).toHaveBeenCalledWith({
          url: '/fixtures/blob/pdf/test.pdf',
          cMapUrl: `/gitlab${process.env.PDF_JS_CMAPS_PUBLIC_PATH}`,
          cMapPacked: true,
          isEvalSupported: true,
        });
        expect(wrapper.isVisible()).toBe(true);
      });

      it('sets worker file path with relative URL root', () => {
        expect(mockGlobalWorkerOptions.workerSrc).toBe(
          `/gitlab/${process.env.PDF_JS_WORKER_PUBLIC_PATH}`,
        );
      });
    });
  });
});
