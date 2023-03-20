import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import EmbedDropdown from '~/snippets/components/embed_dropdown.vue';
import SnippetApp from '~/snippets/components/show.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetTitle from '~/snippets/components/snippet_title.vue';
import {
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import CloneDropdownButton from '~/vue_shared/components/clone_dropdown.vue';
import { stubPerformanceWebAPI } from 'helpers/performance';

describe('Snippet view app', () => {
  let wrapper;
  const defaultProps = {
    snippetGid: 'gid://gitlab/PersonalSnippet/42',
  };
  const webUrl = 'http://foo.bar';
  const dummyHTTPUrl = webUrl;
  const dummySSHUrl = 'ssh://foo.bar';

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
  const findEmbedDropdown = () => wrapper.findComponent(EmbedDropdown);

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
    expect(wrapper.findComponent(SnippetTitle).exists()).toBe(true);
  });

  it('renders embed dropdown component if visibility allows', () => {
    createComponent({
      data: {
        snippet: {
          visibilityLevel: VISIBILITY_LEVEL_PUBLIC_STRING,
          webUrl: 'http://foo.bar',
        },
      },
    });
    expect(findEmbedDropdown().exists()).toBe(true);
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

  describe('Embed dropdown rendering', () => {
    it.each`
      visibilityLevel                     | condition       | isRendered
      ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${'not render'} | ${false}
      ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${'not render'} | ${false}
      ${'foo'}                            | ${'not render'} | ${false}
      ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${'render'}     | ${true}
    `('does $condition embed-dropdown by default', ({ visibilityLevel, isRendered }) => {
      createComponent({
        data: {
          snippet: {
            visibilityLevel,
            webUrl,
          },
        },
      });
      expect(findEmbedDropdown().exists()).toBe(isRendered);
    });
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

  describe('Clone button rendering', () => {
    it.each`
      httpUrlToRepo   | sshUrlToRepo   | shouldRender    | isRendered
      ${null}         | ${null}        | ${'Should not'} | ${false}
      ${null}         | ${dummySSHUrl} | ${'Should'}     | ${true}
      ${dummyHTTPUrl} | ${null}        | ${'Should'}     | ${true}
      ${dummyHTTPUrl} | ${dummySSHUrl} | ${'Should'}     | ${true}
    `(
      '$shouldRender render "Clone" button when `httpUrlToRepo` is $httpUrlToRepo and `sshUrlToRepo` is $sshUrlToRepo',
      ({ httpUrlToRepo, sshUrlToRepo, isRendered }) => {
        createComponent({
          data: {
            snippet: {
              sshUrlToRepo,
              httpUrlToRepo,
            },
          },
        });
        expect(wrapper.findComponent(CloneDropdownButton).exists()).toBe(isRendered);
      },
    );
  });
});
