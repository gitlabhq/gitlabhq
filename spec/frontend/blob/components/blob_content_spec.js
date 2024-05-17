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
        projectPath: 'somePath',
        currentRef: 'test',
        activeViewer,
        ...propsData,
      },
    });
  }

  describe('rendering', () => {
    it('renders loader if `loading: true`', () => {
      createComponent({ loading: true });
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(BlobContentError).exists()).toBe(false);
      expect(wrapper.findComponent(RichViewer).exists()).toBe(false);
      expect(wrapper.findComponent(SimpleViewer).exists()).toBe(false);
    });

    it('renders error if there is any in the viewer', () => {
      const renderError = 'Oops';
      const viewer = { ...SimpleViewerMock, renderError };
      createComponent({}, viewer);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(BlobContentError).exists()).toBe(true);
      expect(wrapper.findComponent(RichViewer).exists()).toBe(false);
      expect(wrapper.findComponent(SimpleViewer).exists()).toBe(false);
    });

    it.each`
      type        | mock                | viewer
      ${'simple'} | ${SimpleViewerMock} | ${SimpleViewer}
      ${'rich'}   | ${RichViewerMock}   | ${RichViewer}
    `(
      'renders $type viewer when activeViewer is $type and no loading or error detected',
      ({ mock, viewer }) => {
        createComponent({}, mock);
        expect(wrapper.findComponent(viewer).exists()).toBe(true);
      },
    );

    it.each`
      content                            | mock                | viewer
      ${SimpleBlobContentMock.plainData} | ${SimpleViewerMock} | ${SimpleViewer}
      ${RichBlobContentMock.richData}    | ${RichViewerMock}   | ${RichViewer}
    `('renders correct content that is passed to the component', ({ content, mock, viewer }) => {
      createComponent({ content }, mock);
      expect(wrapper.findComponent(viewer).html()).toContain(content);
    });

    it.each`
      content                  | lineNumbers
      ${null}                  | ${0}
      ${'line 1'}              | ${1}
      ${'line 1 \n line 2'}    | ${2}
      ${'line 1 \n line 2 \n'} | ${3}
    `(
      'renders correct amount of line numbers for the simple viewer',
      ({ content, lineNumbers }) => {
        createComponent({ blob: { ...Blob, rawTextBlob: content }, content });
        expect(wrapper.findComponent(SimpleViewer).props('lineNumbers')).toBe(lineNumbers);
      },
    );
  });

  describe('functionality', () => {
    describe('render error', () => {
      const findErrorEl = () => wrapper.findComponent(BlobContentError);
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
        expect(wrapper.emitted(BLOB_RENDER_EVENT_LOAD)).toHaveLength(1);
      });

      it(`properly proxies ${BLOB_RENDER_EVENT_SHOW_SOURCE} event`, () => {
        expect(wrapper.emitted(BLOB_RENDER_EVENT_SHOW_SOURCE)).toBeUndefined();
        findErrorEl().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE);
        expect(wrapper.emitted(BLOB_RENDER_EVENT_SHOW_SOURCE)).toHaveLength(1);
      });
    });
  });
});
