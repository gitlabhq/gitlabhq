import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import { FIXTURES_PATH } from 'spec/test_constants';
import component from '~/blob/pdf/pdf_viewer.vue';
import PdfLab from '~/pdf/index.vue';

const testPDF = `${FIXTURES_PATH}/blob/pdf/test.pdf`;

describe('PDF renderer', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      propsData: {
        pdf: testPDF,
      },
    });
  };

  const findLoading = () => wrapper.find(GlLoadingIcon);
  const findPdfLab = () => wrapper.find(PdfLab);
  const findLoadError = () => wrapper.find({ ref: 'loadError' });

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows loading icon', () => {
    expect(findLoading().exists()).toBe(true);
  });

  describe('successful response', () => {
    beforeEach(() => {
      findPdfLab().vm.$emit('pdflabload');
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('renders the PDF', () => {
      expect(findPdfLab().exists()).toBe(true);
    });
  });

  describe('error getting file', () => {
    beforeEach(() => {
      findPdfLab().vm.$emit('pdflaberror', 'foo');
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('shows error message', () => {
      expect(findLoadError().text()).toBe(
        'An error occurred while loading the file. Please try again later.',
      );
    });
  });
});
