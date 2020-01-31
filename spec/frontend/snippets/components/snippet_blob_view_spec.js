import { shallowMount } from '@vue/test-utils';
import SnippetBlobView from '~/snippets/components/snippet_blob_view.vue';
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import {
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PUBLIC,
} from '~/snippets/constants';

describe('Blob Embeddable', () => {
  let wrapper;
  const snippet = {
    id: 'gid://foo.bar/snippet',
    webUrl: 'https://foo.bar',
    visibilityLevel: SNIPPET_VISIBILITY_PUBLIC,
  };

  function createComponent(props = {}) {
    wrapper = shallowMount(SnippetBlobView, {
      propsData: {
        snippet: {
          ...snippet,
          ...props,
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders blob-embeddable component', () => {
    createComponent();
    expect(wrapper.find(BlobEmbeddable).exists()).toBe(true);
  });

  it('does not render blob-embeddable for internal snippet', () => {
    createComponent({
      visibilityLevel: SNIPPET_VISIBILITY_INTERNAL,
    });
    expect(wrapper.find(BlobEmbeddable).exists()).toBe(false);

    createComponent({
      visibilityLevel: SNIPPET_VISIBILITY_PRIVATE,
    });
    expect(wrapper.find(BlobEmbeddable).exists()).toBe(false);

    createComponent({
      visibilityLevel: 'foo',
    });
    expect(wrapper.find(BlobEmbeddable).exists()).toBe(false);
  });
});
