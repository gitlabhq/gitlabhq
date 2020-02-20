import { shallowMount } from '@vue/test-utils';
import RichViewer from '~/vue_shared/components/blob_viewers/rich_viewer.vue';

describe('Blob Rich Viewer component', () => {
  let wrapper;
  const content = '<h1 id="markdown">Foo Bar</h1>';

  function createComponent() {
    wrapper = shallowMount(RichViewer, {
      propsData: {
        content,
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
});
