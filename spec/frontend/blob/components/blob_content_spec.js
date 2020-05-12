import { shallowMount } from '@vue/test-utils';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobContentError from '~/blob/components/blob_content_error.vue';
import {
  RichViewerMock,
  SimpleViewerMock,
  RichBlobContentMock,
  SimpleBlobContentMock,
} from './mock_data';
import { GlLoadingIcon } from '@gitlab/ui';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';

describe('Blob Content component', () => {
  let wrapper;

  function createComponent(propsData = {}, activeViewer = SimpleViewerMock) {
    wrapper = shallowMount(BlobContent, {
      propsData: {
        loading: false,
        activeViewer,
        ...propsData,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('renders loader if `loading: true`', () => {
      createComponent({ loading: true });
      expect(wrapper.contains(GlLoadingIcon)).toBe(true);
      expect(wrapper.contains(BlobContentError)).toBe(false);
      expect(wrapper.contains(RichViewer)).toBe(false);
      expect(wrapper.contains(SimpleViewer)).toBe(false);
    });

    it('renders error if there is any in the viewer', () => {
      const renderError = 'Oops';
      const viewer = { ...SimpleViewerMock, renderError };
      createComponent({}, viewer);
      expect(wrapper.contains(GlLoadingIcon)).toBe(false);
      expect(wrapper.contains(BlobContentError)).toBe(true);
      expect(wrapper.contains(RichViewer)).toBe(false);
      expect(wrapper.contains(SimpleViewer)).toBe(false);
    });

    it.each`
      type        | mock                | viewer
      ${'simple'} | ${SimpleViewerMock} | ${SimpleViewer}
      ${'rich'}   | ${RichViewerMock}   | ${RichViewer}
    `(
      'renders $type viewer when activeViewer is $type and no loading or error detected',
      ({ mock, viewer }) => {
        createComponent({}, mock);
        expect(wrapper.contains(viewer)).toBe(true);
      },
    );

    it.each`
      content                            | mock                | viewer
      ${SimpleBlobContentMock.plainData} | ${SimpleViewerMock} | ${SimpleViewer}
      ${RichBlobContentMock.richData}    | ${RichViewerMock}   | ${RichViewer}
    `('renders correct content that is passed to the component', ({ content, mock, viewer }) => {
      createComponent({ content }, mock);
      expect(wrapper.find(viewer).html()).toContain(content);
    });
  });
});
