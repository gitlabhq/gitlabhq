import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { handleBlobRichViewer } from '~/blob/viewer';
import RichViewer from '~/vue_shared/components/blob_viewers/rich_viewer.vue';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import {
  MARKUP_FILE_TYPE,
  CONTENT_LOADED_EVENT,
} from '~/vue_shared/components/blob_viewers/constants';
import { handleLocationHash } from '~/lib/utils/common_utils';

jest.mock('~/blob/viewer');
jest.mock('~/lib/utils/common_utils');

describe('Blob Rich Viewer component', () => {
  let wrapper;
  const dummyContent = '<h1 id="markdown">Foo Bar</h1>';
  const defaultType = 'markdown';

  function createComponent(type = defaultType, richViewer, content = dummyContent) {
    wrapper = shallowMount(RichViewer, {
      propsData: {
        richViewer,
        content,
        type,
      },
    });
  }

  beforeEach(() => createComponent());

  const findMarkdownFieldView = () => wrapper.findComponent(MarkdownFieldView);

  describe('Markdown content', () => {
    const generateDummyContent = (contentLength) => {
      let generatedContent = '';
      for (let i = 0; i < contentLength; i += 1) {
        generatedContent += `<span>Line: ${i + 1}</span>\n`;
      }

      generatedContent +=
        '<img src="x" onerror="alert(`XSS`)" style="position:fixed;" data-lines-path="test/xss.json" data-remote="xss">'; // for testing against XSS
      return `<div class="js-markup-content">${generatedContent}</div>`;
    };

    describe('Large file', () => {
      const content = generateDummyContent(50);
      beforeEach(() => createComponent(MARKUP_FILE_TYPE, null, content));

      it('renders the top of the file immediately and does not emit a content loaded event', () => {
        expect(wrapper.text()).toContain('Line: 10');
        expect(wrapper.text()).not.toContain('Line: 50');
        expect(wrapper.emitted(CONTENT_LOADED_EVENT)).toBeUndefined();
        expect(findMarkdownFieldView().props('isLoading')).toBe(true);
      });

      it('renders the rest of the file later and emits a content loaded event', async () => {
        jest.runAllTimers();
        await nextTick();

        expect(wrapper.text()).toContain('Line: 10');
        expect(wrapper.text()).toContain('Line: 50');
        expect(wrapper.emitted(CONTENT_LOADED_EVENT)).toHaveLength(1);
        expect(handleLocationHash).toHaveBeenCalled();
        expect(findMarkdownFieldView().props('isLoading')).toBe(false);
      });

      it('sanitizes the content', () => {
        jest.runAllTimers();

        expect(wrapper.html()).toContain('<img src="x">');
      });
    });

    describe('Small file', () => {
      const content = generateDummyContent(5);
      beforeEach(() => createComponent(MARKUP_FILE_TYPE, null, content));

      it('renders the entire file immediately and emits a content loaded event', () => {
        expect(wrapper.text()).toContain('Line: 5');
        expect(wrapper.emitted(CONTENT_LOADED_EVENT)).toHaveLength(1);
        expect(findMarkdownFieldView().props('isLoading')).toBe(false);
      });

      it('sanitizes the content', () => {
        expect(wrapper.html()).toContain('<img src="x">');
      });
    });
  });

  it('renders the passed content without transformations', () => {
    expect(wrapper.html()).toContain(dummyContent);
  });

  it('renders the richViewer if one is present and emits a content loaded event', async () => {
    const richViewer = '<div class="js-pdf-viewer"></div>';
    createComponent('pdf', richViewer);
    await nextTick();
    expect(wrapper.html()).toContain(richViewer);
    expect(wrapper.emitted(CONTENT_LOADED_EVENT)).toHaveLength(1);
  });

  it('queries for advanced viewer', () => {
    expect(handleBlobRichViewer).toHaveBeenCalledWith(expect.anything(), defaultType);
  });

  it('is using Markdown View Field', () => {
    expect(findMarkdownFieldView().exists()).toBe(true);
  });

  it('scrolls to the hash location', () => {
    expect(handleLocationHash).toHaveBeenCalled();
  });
});
