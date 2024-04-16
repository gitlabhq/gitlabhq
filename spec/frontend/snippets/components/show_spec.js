import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import SnippetApp from '~/snippets/components/show.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetDescription from '~/snippets/components/snippet_description.vue';
import { stubPerformanceWebAPI } from 'helpers/performance';

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

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    stubPerformanceWebAPI();
  });

  it('renders loader while the query is in flight', () => {
    createComponent({ loading: true });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders all simple components required after the query is finished', () => {
    createComponent();
    expect(wrapper.findComponent(SnippetHeader).exists()).toBe(true);
    expect(wrapper.findComponent(SnippetDescription).exists()).toBe(true);
  });

  it('renders correct snippet-blob components', () => {
    createComponent({
      data: {
        snippet: {
          blobs: [Blob, BinaryBlob],
        },
      },
    });
    const blobs = wrapper.findAllComponents(SnippetBlob);
    expect(blobs.length).toBe(2);
    expect(blobs.at(0).props('blob')).toEqual(Blob);
    expect(blobs.at(1).props('blob')).toEqual(BinaryBlob);
  });

  describe('hasUnretrievableBlobs alert rendering', () => {
    it.each`
      hasUnretrievableBlobs | condition       | isRendered
      ${false}              | ${'not render'} | ${false}
      ${true}               | ${'render'}     | ${true}
    `('does $condition gl-alert by default', ({ hasUnretrievableBlobs, isRendered }) => {
      createComponent({
        data: {
          snippet: {
            hasUnretrievableBlobs,
          },
        },
      });
      expect(wrapper.findComponent(GlAlert).exists()).toBe(isRendered);
    });
  });
});
