import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import SnippetApp from '~/snippets/components/show.vue';
import SnippetBlob from '~/snippets/components/snippet_blob_view.vue';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import SnippetDescription from '~/snippets/components/snippet_description.vue';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { createGQLSnippet, createGQLSnippetsQueryResponse } from '../test_utils';

Vue.use(VueApollo);

const createGQLBlobViewer = (type, fileType) => ({
  __typename: 'SnippetBlobViewer',
  collapsed: false,
  renderError: null,
  tooLarge: false,
  type,
  fileType,
});

const createGQLBlob = ({ name, path, binary = false }) => ({
  __typename: 'SnippetBlob',
  binary,
  name,
  path,
  rawPath: `/snippets/42/raw/main/${name}`,
  size: 75,
  externalStorage: null,
  renderedAsText: false,
  simpleViewer: createGQLBlobViewer('simple', 'text'),
  richViewer: createGQLBlobViewer('rich', 'markdown'),
});

const TEXT_BLOB = createGQLBlob({ name: 'dummy.md', path: 'foo/bar/dummy.md' });
const BINARY_BLOB = createGQLBlob({ name: 'dummy.png', path: 'foo/bar/dummy.png', binary: true });

describe('Snippet view app', () => {
  let wrapper;
  const defaultProps = {
    snippetGid: 'gid://gitlab/PersonalSnippet/42',
  };

  const createQueryResponse = (snippet = {}) =>
    createGQLSnippetsQueryResponse([
      {
        ...createGQLSnippet(),
        webUrl: '/snippets/42',
        visibilityLevel: 'private',
        blobs: {
          __typename: 'SnippetBlobConnection',
          hasUnretrievableBlobs: false,
          nodes: [],
        },
        ...snippet,
      },
    ]);

  function createComponent({ props = defaultProps, snippet = {} } = {}) {
    const apolloProvider = createMockApollo([
      [GetSnippetQuery, jest.fn().mockResolvedValue(createQueryResponse(snippet))],
    ]);

    wrapper = shallowMount(SnippetApp, {
      apolloProvider,
      propsData: {
        ...props,
      },
    });
  }

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    stubPerformanceWebAPI();
  });

  it('renders loader while the query is in flight', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders all simple components required after the query is finished', async () => {
    createComponent();
    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(wrapper.findComponent(SnippetHeader).exists()).toBe(true);
    expect(wrapper.findComponent(SnippetDescription).exists()).toBe(true);
  });

  it('renders correct snippet-blob components', async () => {
    createComponent({
      snippet: {
        blobs: {
          __typename: 'SnippetBlobConnection',
          hasUnretrievableBlobs: false,
          nodes: [TEXT_BLOB, BINARY_BLOB],
        },
      },
    });
    await waitForPromises();

    const blobs = wrapper.findAllComponents(SnippetBlob);

    expect(blobs).toHaveLength(2);
    expect(blobs.at(0).props('blob')).toEqual(TEXT_BLOB);
    expect(blobs.at(1).props('blob')).toEqual(BINARY_BLOB);
  });

  describe('hasUnretrievableBlobs alert rendering', () => {
    it.each`
      hasUnretrievableBlobs | condition       | isRendered
      ${false}              | ${'not render'} | ${false}
      ${true}               | ${'render'}     | ${true}
    `('does $condition gl-alert by default', async ({ hasUnretrievableBlobs, isRendered }) => {
      createComponent({
        snippet: {
          blobs: {
            __typename: 'SnippetBlobConnection',
            hasUnretrievableBlobs,
            nodes: [],
          },
        },
      });
      await waitForPromises();

      expect(wrapper.findComponent(GlAlert).exists()).toBe(isRendered);
    });
  });
});
