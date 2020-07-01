import SnippetApp from '~/snippets/components/show.vue';
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetTitle from '~/snippets/components/snippet_title.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';

import { shallowMount } from '@vue/test-utils';
import { SNIPPET_VISIBILITY_PUBLIC } from '~/snippets/constants';

describe('Snippet view app', () => {
  let wrapper;
  const defaultProps = {
    snippetGid: 'gid://gitlab/PersonalSnippet/42',
  };

  function createComponent({ props = defaultProps, data = {}, loading = false } = {}) {
    const $apollo = {
      queries: {
        snippet: {
          loading,
        },
      },
    };

    wrapper = shallowMount(SnippetApp, {
      mocks: { $apollo },
      propsData: {
        ...props,
      },
      data() {
        return data;
      },
    });
  }
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders loader while the query is in flight', () => {
    createComponent({ loading: true });
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders all simple components after the query is finished', () => {
    createComponent();
    expect(wrapper.find(SnippetHeader).exists()).toBe(true);
    expect(wrapper.find(SnippetTitle).exists()).toBe(true);
  });

  it('renders embeddable component if visibility allows', () => {
    createComponent({
      data: {
        snippet: {
          visibilityLevel: SNIPPET_VISIBILITY_PUBLIC,
          webUrl: 'http://foo.bar',
        },
      },
    });
    expect(wrapper.contains(BlobEmbeddable)).toBe(true);
  });

  it('renders correct snippet-blob components', () => {
    createComponent({
      data: {
        blobs: [Blob, BinaryBlob],
      },
    });
    const blobs = wrapper.findAll(SnippetBlob);
    expect(blobs.length).toBe(2);
    expect(blobs.at(0).props('blob')).toEqual(Blob);
    expect(blobs.at(1).props('blob')).toEqual(BinaryBlob);
  });
});
