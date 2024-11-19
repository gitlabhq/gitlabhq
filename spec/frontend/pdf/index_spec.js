import { shallowMount } from '@vue/test-utils';
// eslint-disable-next-line import/extensions
import { GlobalWorkerOptions as GlobalWorkerOptionsV4 } from 'pdfjs-dist-v4/legacy/build/pdf.mjs';
import { GlobalWorkerOptions as GlobalWorkerOptionsV3 } from 'pdfjs-dist-v3/legacy/build/pdf';
import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

describe('PDFLab component', () => {
  let wrapper;

  const mountComponent = ({ pdf, flagValue = true }) =>
    shallowMount(PDFLab, {
      propsData: { pdf },
      provide: { glFeatures: { upgradePdfjs: flagValue } },
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
    describe('when upgradePdfjs flag is on', () => {
      let mockGetDocument;
      beforeEach(async () => {
        mockGetDocument = jest.fn().mockReturnValue({ promise: Promise.resolve() });
        jest.mock('pdfjs-dist-v4/legacy/build/pdf.mjs', () => ({
          ...jest.requireActual('pdfjs-dist-v4/legacy/build/pdf.mjs'),
          getDocument: mockGetDocument,
        }));
        wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf` });
        await wrapper.vm.load();
      });

      it('renders with pdfjs-dist v4', () => {
        expect(mockGetDocument).toHaveBeenCalledWith({
          url: '/fixtures/blob/pdf/test.pdf',
          cMapUrl: process.env.PDF_JS_CMAPS_V4_PUBLIC_PATH,
          cMapPacked: true,
          isEvalSupported: true,
        });
        expect(wrapper.isVisible()).toBe(true);
      });

      it('gets worker file path from environment var', () => {
        expect(GlobalWorkerOptionsV4.workerSrc).toBe('mock/path/v4/pdf.worker.js');
      });
    });

    describe('when upgradePdfjs flag is off', () => {
      let mockGetDocument;

      beforeEach(async () => {
        mockGetDocument = jest.fn().mockReturnValue({ promise: Promise.resolve() });
        jest.mock('pdfjs-dist-v3/legacy/build/pdf', () => ({
          ...jest.requireActual('pdfjs-dist-v3/legacy/build/pdf'),
          getDocument: mockGetDocument,
        }));
        wrapper = mountComponent({ pdf: `${FIXTURES_PATH}/blob/pdf/test.pdf`, flagValue: false });
        await wrapper.vm.load();
      });

      it('renders with pdfjs-dist v3', () => {
        expect(mockGetDocument).toHaveBeenCalledWith({
          url: '/fixtures/blob/pdf/test.pdf',
          cMapUrl: process.env.PDF_JS_CMAPS_V3_PUBLIC_PATH,
          cMapPacked: true,
          isEvalSupported: false,
        });
        expect(wrapper.isVisible()).toBe(true);
      });

      it('gets worker file path from environment var', () => {
        expect(GlobalWorkerOptionsV3.workerSrc).toBe('mock/path/v3/pdf.worker.js');
      });
    });
  });
});
