import { shallowMount } from '@vue/test-utils';
import { handleBlobRichViewer } from '~/blob/viewer';
import RichViewer from '~/vue_shared/components/blob_viewers/rich_viewer.vue';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';

jest.mock('~/blob/viewer');

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
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the passed content without transformations', () => {
    expect(wrapper.html()).toContain(content);
  });

  it('renders the richViewer if one is present', () => {
    const richViewer = '<div class="js-pdf-viewer"></div>';
    createComponent('pdf', richViewer);
    expect(wrapper.html()).toContain(richViewer);
  });

  it('queries for advanced viewer', () => {
    expect(handleBlobRichViewer).toHaveBeenCalledWith(expect.anything(), defaultType);
  });

  it('is using Markdown View Field', () => {
    expect(wrapper.find(MarkdownFieldView).exists()).toBe(true);
  });
});
