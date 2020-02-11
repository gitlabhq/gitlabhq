import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import SnippetBlobView from '~/snippets/components/snippet_blob_view.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
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

  function createComponent(props = {}, loading = false) {
    const $apollo = {
      queries: {
        blob: {
          loading,
        },
      },
    };

    wrapper = shallowMount(SnippetBlobView, {
      propsData: {
        snippet: {
          ...snippet,
          ...props,
        },
      },
      mocks: { $apollo },
    });

    wrapper.vm.$apollo.queries.blob.loading = false;
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('renders correct components', () => {
      createComponent();
      expect(wrapper.find(BlobEmbeddable).exists()).toBe(true);
      expect(wrapper.find(BlobHeader).exists()).toBe(true);
    });

    it.each([SNIPPET_VISIBILITY_INTERNAL, SNIPPET_VISIBILITY_PRIVATE, 'foo'])(
      'does not render blob-embeddable by default',
      visibilityLevel => {
        createComponent({
          visibilityLevel,
        });
        expect(wrapper.find(BlobEmbeddable).exists()).toBe(false);
      },
    );

    it('does render blob-embeddable for public snippet', () => {
      createComponent({
        visibilityLevel: SNIPPET_VISIBILITY_PUBLIC,
      });
      expect(wrapper.find(BlobEmbeddable).exists()).toBe(true);
    });

    it('shows loading icon while blob data is in flight', () => {
      createComponent({}, true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find('.snippet-file-content').exists()).toBe(false);
    });
  });
});
