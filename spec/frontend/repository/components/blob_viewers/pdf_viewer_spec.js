import { shallowMount } from '@vue/test-utils';
import Component from '~/repository/components/blob_viewers/pdf_viewer.vue';
import PdfViewer from '~/blob/pdf/pdf_viewer.vue';

describe('PDF Viewer', () => {
  let wrapper;

  const propsData = { url: 'some/pdf_blob.pdf' };

  const createComponent = () => {
    wrapper = shallowMount(Component, { propsData });
  };

  const findPDFViewer = () => wrapper.findComponent(PdfViewer);

  it('renders a PDF Viewer component', () => {
    createComponent();

    expect(findPDFViewer().exists()).toBe(true);
    expect(findPDFViewer().props('pdf')).toBe(propsData.url);
  });
});
