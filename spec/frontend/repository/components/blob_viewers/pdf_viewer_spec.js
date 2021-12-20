import { GlButton } from '@gitlab/ui';
import Component from '~/repository/components/blob_viewers/pdf_viewer.vue';
import PdfViewer from '~/blob/pdf/pdf_viewer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PDF Viewer', () => {
  let wrapper;

  const defaultPropsData = { url: 'some/pdf_blob.pdf' };

  const createComponent = (fileSize = 999) => {
    wrapper = shallowMountExtended(Component, { propsData: { ...defaultPropsData, fileSize } });
  };

  const findPDFViewer = () => wrapper.findComponent(PdfViewer);
  const findHelpText = () => wrapper.find('p');
  const findDownLoadButton = () => wrapper.findComponent(GlButton);

  it('renders a PDF Viewer component', () => {
    createComponent();

    expect(findPDFViewer().exists()).toBe(true);
    expect(findPDFViewer().props('pdf')).toBe(defaultPropsData.url);
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
    beforeEach(() => {
      createComponent();
      findPDFViewer().vm.$emit('pdflabload', 100);
    });

    it('does not a PDF Viewer component', () => {
      expect(findPDFViewer().exists()).toBe(false);
    });

    it('renders a download button', () => {
      expect(findDownLoadButton().exists()).toBe(true);
    });
  });
});
