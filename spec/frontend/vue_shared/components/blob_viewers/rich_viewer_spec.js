import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { handleBlobRichViewer } from '~/blob/viewer';
import RichViewer from '~/vue_shared/components/blob_viewers/rich_viewer.vue';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { handleLocationHash } from '~/lib/utils/common_utils';

jest.mock('~/blob/viewer');
jest.mock('~/lib/utils/common_utils');

describe('Blob Rich Viewer component', () => {
  let wrapper;
  const content = '<h1 id="markdown">Foo Bar</h1>';
  const defaultType = 'markdown';

  function createComponent(type = defaultType, richViewer) {
    wrapper = shallowMount(RichViewer, {
      propsData: {
        richViewer,
        content,
        type,
      },
    });
  }

  beforeEach(() => {
    const execImmediately = (callback) => callback();
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);

    createComponent();
  });

  it('listens to requestIdleCallback', () => {
    expect(window.requestIdleCallback).toHaveBeenCalled();
  });

  it('renders the passed content without transformations', () => {
    expect(wrapper.html()).toContain(content);
  });

  it('renders the richViewer if one is present', async () => {
    const richViewer = '<div class="js-pdf-viewer"></div>';
    createComponent('pdf', richViewer);
    await nextTick();
    expect(wrapper.html()).toContain(richViewer);
  });

  it('queries for advanced viewer', () => {
    expect(handleBlobRichViewer).toHaveBeenCalledWith(expect.anything(), defaultType);
  });

  it('is using Markdown View Field', () => {
    expect(wrapper.findComponent(MarkdownFieldView).exists()).toBe(true);
  });

  it('scrolls to the hash location', () => {
    expect(handleLocationHash).toHaveBeenCalled();
  });
});
