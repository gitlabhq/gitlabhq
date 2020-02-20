import SnippetApp from '~/snippets/components/app.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetTitle from '~/snippets/components/snippet_title.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import { GlLoadingIcon } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';

describe('Snippet view app', () => {
  let wrapper;
  const defaultProps = {
    snippetGid: 'gid://gitlab/PersonalSnippet/42',
  };

  function createComponent({ props = defaultProps, loading = false } = {}) {
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
    });
  }
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders loader while the query is in flight', () => {
    createComponent({ loading: true });
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders all components after the query is finished', () => {
    createComponent();
    expect(wrapper.find(SnippetHeader).exists()).toBe(true);
    expect(wrapper.find(SnippetTitle).exists()).toBe(true);
    expect(wrapper.find(SnippetBlob).exists()).toBe(true);
  });
});
