import { GlLoadingIcon } from '@gitlab/ui';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import { shallowMount } from '@vue/test-utils';
import SnippetApp from '~/snippets/components/show.vue';
import EmbedDropdown from '~/snippets/components/embed_dropdown.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetTitle from '~/snippets/components/snippet_title.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import CloneDropdownButton from '~/vue_shared/components/clone_dropdown.vue';

import {
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_PUBLIC,
} from '~/snippets/constants';

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

  it('renders embed dropdown component if visibility allows', () => {
    createComponent({
      data: {
        snippet: {
          visibilityLevel: SNIPPET_VISIBILITY_PUBLIC,
          webUrl: 'http://foo.bar',
        },
      },
    });
    expect(wrapper.find(EmbedDropdown).exists()).toBe(true);
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

  describe('Embed dropdown rendering', () => {
    it.each`
      visibilityLevel                | condition       | isRendered
      ${SNIPPET_VISIBILITY_INTERNAL} | ${'not render'} | ${false}
      ${SNIPPET_VISIBILITY_PRIVATE}  | ${'not render'} | ${false}
      ${'foo'}                       | ${'not render'} | ${false}
      ${SNIPPET_VISIBILITY_PUBLIC}   | ${'render'}     | ${true}
    `('does $condition embed-dropdown by default', ({ visibilityLevel, isRendered }) => {
      createComponent({
        data: {
          snippet: {
            visibilityLevel,
            webUrl,
          },
        },
      });
      expect(wrapper.find(EmbedDropdown).exists()).toBe(isRendered);
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
        expect(wrapper.find(CloneDropdownButton).exists()).toBe(isRendered);
      },
    );
  });
});
