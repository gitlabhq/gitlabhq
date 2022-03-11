import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import Component from '~/repository/components/blob_viewers/pdf_viewer.vue';
import PdfViewer from '~/blob/pdf/pdf_viewer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PDF Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = { rawPath: 'some/pdf_blob.pdf' };

  const createComponent = (rawSize = 999, externalStorageUrl) => {
    wrapper = shallowMountExtended(Component, {
      propsData: { blob: { ...DEFAULT_BLOB_DATA, rawSize, externalStorageUrl } },
    });
  };

  const findPDFViewer = () => wrapper.findComponent(PdfViewer);
  const findHelpText = () => wrapper.find('p');
  const findDownLoadButton = () => wrapper.findComponent(GlButton);

  it('renders a PDF Viewer component', () => {
    createComponent();

    expect(findPDFViewer().exists()).toBe(true);
    expect(findPDFViewer().props('pdf')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });

  describe('Too large', () => {
    beforeEach(() => createComponent(20000000));

    it('does not a PDF Viewer component', () => {
      expect(findPDFViewer().exists()).toBe(false);
    });

    it('renders help text', () => {
      expect(findHelpText().text()).toBe(
        'This PDF is too large to display. Please download to view.',
      );
    });

    it('renders a download button', () => {
      expect(findDownLoadButton().text()).toBe('Download PDF');
      expect(findDownLoadButton().props('icon')).toBe('download');
    });
  });

  describe('Too many pages', () => {
    const loadComponent = (externalStorageUrl) => {
      const rawSize = 999;
      const totalPages = 100;
      createComponent(rawSize, externalStorageUrl);
      findPDFViewer().vm.$emit('pdflabload', totalPages);
    };

    beforeEach(() => loadComponent());

    it('does not a PDF Viewer component', () => {
      expect(findPDFViewer().exists()).toBe(false);
    });

    it('renders a download button', () => {
      expect(findDownLoadButton().exists()).toBe(true);
      expect(findDownLoadButton().attributes('href')).toBe(DEFAULT_BLOB_DATA.rawPath);
    });

    it('renders the correct href when stored externally', async () => {
      const externalStorageUrl = 'https://cdn.test.com/project/some/file.js?token=1234';
      loadComponent(externalStorageUrl);
      await nextTick();

      expect(findDownLoadButton().attributes('href')).toBe(externalStorageUrl);
    });
  });
});
