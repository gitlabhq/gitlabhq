import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobContentError from '~/blob/components/blob_content_error.vue';
import {
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
  BLOB_RENDER_ERRORS,
} from '~/blob/components/constants';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';
import {
  Blob,
  RichViewerMock,
  SimpleViewerMock,
  RichBlobContentMock,
  SimpleBlobContentMock,
} from './mock_data';

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
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(BlobContentError).exists()).toBe(false);
      expect(wrapper.find(RichViewer).exists()).toBe(false);
      expect(wrapper.find(SimpleViewer).exists()).toBe(false);
    });

    it('renders error if there is any in the viewer', () => {
      const renderError = 'Oops';
      const viewer = { ...SimpleViewerMock, renderError };
      createComponent({}, viewer);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(BlobContentError).exists()).toBe(true);
      expect(wrapper.find(RichViewer).exists()).toBe(false);
      expect(wrapper.find(SimpleViewer).exists()).toBe(false);
    });

    it.each`
      type        | mock                | viewer
      ${'simple'} | ${SimpleViewerMock} | ${SimpleViewer}
      ${'rich'}   | ${RichViewerMock}   | ${RichViewer}
    `(
      'renders $type viewer when activeViewer is $type and no loading or error detected',
      ({ mock, viewer }) => {
        createComponent({}, mock);
        expect(wrapper.find(viewer).exists()).toBe(true);
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

  describe('functionality', () => {
    describe('render error', () => {
      const findErrorEl = () => wrapper.find(BlobContentError);
      const renderError = BLOB_RENDER_ERRORS.REASONS.COLLAPSED.id;
      const viewer = { ...SimpleViewerMock, renderError };

      beforeEach(() => {
        createComponent({ blob: Blob }, viewer);
      });

      it('correctly sets blob on the blob-content-error component', () => {
        expect(findErrorEl().props('blob')).toEqual(Blob);
      });

      it(`properly proxies ${BLOB_RENDER_EVENT_LOAD} event`, () => {
        expect(wrapper.emitted(BLOB_RENDER_EVENT_LOAD)).toBeUndefined();
        findErrorEl().vm.$emit(BLOB_RENDER_EVENT_LOAD);
        expect(wrapper.emitted(BLOB_RENDER_EVENT_LOAD)).toBeTruthy();
      });

      it(`properly proxies ${BLOB_RENDER_EVENT_SHOW_SOURCE} event`, () => {
        expect(wrapper.emitted(BLOB_RENDER_EVENT_SHOW_SOURCE)).toBeUndefined();
        findErrorEl().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE);
        expect(wrapper.emitted(BLOB_RENDER_EVENT_SHOW_SOURCE)).toBeTruthy();
      });
    });
  });
});
