import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import {
  Blob as BlobMock,
  SimpleViewerMock,
  RichViewerMock,
  RichBlobContentMock,
  SimpleBlobContentMock,
} from 'jest/blob/components/mock_data';
import GetBlobContent from 'shared_queries/snippet/snippet_blob_content.query.graphql';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import {
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
  BLOB_RENDER_ERRORS,
} from '~/blob/components/constants';
import SnippetBlobView from '~/snippets/components/snippet_blob_view.vue';
import { VISIBILITY_LEVEL_PUBLIC_STRING } from '~/visibility_level/constants';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

describe('Blob Embeddable', () => {
  let wrapper;
  let requestHandlers;

  const snippet = {
    id: 'gid://foo.bar/snippet',
    webUrl: 'https://foo.bar',
    visibilityLevel: VISIBILITY_LEVEL_PUBLIC_STRING,
  };
  const dataMock = {
    activeViewerType: SimpleViewerMock.type,
  };

  const mockDefaultHandler = ({ path, nodes } = { path: BlobMock.path }) => {
    const renderedNodes = nodes || [
      { __typename: 'Blob', path, richData: 'richData', plainData: 'plainData' },
    ];

    return jest.fn().mockResolvedValue({
      data: {
        snippets: {
          __typename: 'Snippet',
          id: '1',
          nodes: [
            {
              __typename: 'Snippet',
              id: '2',
              blobs: {
                __typename: 'Blob',
                hasUnretrievableBlobs: false,
                nodes: renderedNodes,
              },
            },
          ],
        },
      },
    });
  };

  const createMockApolloProvider = (handler) => {
    Vue.use(VueApollo);

    requestHandlers = handler;
    return createMockApollo([[GetBlobContent, requestHandlers]]);
  };

  function createComponent({
    snippetProps = {},
    data = dataMock,
    blob = BlobMock,
    handler = mockDefaultHandler(),
  } = {}) {
    wrapper = shallowMount(SnippetBlobView, {
      apolloProvider: createMockApolloProvider(handler),
      propsData: {
        snippet: {
          ...snippet,
          ...snippetProps,
        },
        blob,
      },
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        BlobHeader,
        BlobContent,
      },
    });
  }

  const findBlobHeader = () => wrapper.findComponent(BlobHeader);
  const findBlobContent = () => wrapper.findComponent(BlobContent);
  const findSimpleViewer = () => wrapper.findComponent(SimpleViewer);
  const findRichViewer = () => wrapper.findComponent(RichViewer);

  describe('rendering', () => {
    it('renders correct components', () => {
      createComponent();
      expect(findBlobHeader().exists()).toBe(true);
      expect(findBlobContent().exists()).toBe(true);
    });

    it('passes `isBlameLinkHidden = true` to blob content component', () => {
      createComponent();
      expect(findBlobContent().props('isBlameLinkHidden')).toEqual(true);
    });

    it('sets simple viewer correctly', async () => {
      createComponent();
      await waitForPromises();

      expect(findSimpleViewer().exists()).toBe(true);
    });

    it('sets rich viewer correctly', async () => {
      const data = { ...dataMock, activeViewerType: RichViewerMock.type };
      createComponent({
        data,
      });
      await waitForPromises();
      expect(findRichViewer().exists()).toBe(true);
    });

    it('correctly switches viewer type', async () => {
      createComponent();
      await waitForPromises();

      expect(findSimpleViewer().exists()).toBe(true);

      findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, RichViewerMock.type);
      await waitForPromises();

      expect(findRichViewer().exists()).toBe(true);

      findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, SimpleViewerMock.type);
      await waitForPromises();

      expect(findSimpleViewer().exists()).toBe(true);
    });

    it('passes information about render error down to blob header', () => {
      createComponent({
        blob: {
          ...BlobMock,
          simpleViewer: {
            ...SimpleViewerMock,
            renderError: BLOB_RENDER_ERRORS.REASONS.COLLAPSED.id,
          },
        },
      });

      expect(findBlobHeader().props('hasRenderError')).toBe(true);
    });

    describe('bob content in multi-file scenario', () => {
      const SimpleBlobContentMock2 = {
        ...SimpleBlobContentMock,
        plainData: 'Another Plain Foo',
      };
      const RichBlobContentMock2 = {
        ...SimpleBlobContentMock,
        richData: 'Another Rich Foo',
      };

      const MixedSimpleBlobContentMock = {
        ...SimpleBlobContentMock,
        richData: '<h1>Rich</h1>',
      };

      const MixedRichBlobContentMock = {
        ...RichBlobContentMock,
        plainData: 'Plain',
      };

      it.each`
        snippetBlobs                                         | description                                  | currentBlob              | expectedContent                    | activeViewerType
        ${[SimpleBlobContentMock]}                           | ${'one existing textual blob'}               | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData} | ${SimpleViewerMock.type}
        ${[RichBlobContentMock]}                             | ${'one existing rich blob'}                  | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}    | ${RichViewerMock.type}
        ${[SimpleBlobContentMock, MixedRichBlobContentMock]} | ${'mixed blobs with current textual blob'}   | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData} | ${SimpleViewerMock.type}
        ${[MixedSimpleBlobContentMock, RichBlobContentMock]} | ${'mixed blobs with current rich blob'}      | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}    | ${RichViewerMock.type}
        ${[SimpleBlobContentMock, SimpleBlobContentMock2]}   | ${'textual blobs with current textual blob'} | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData} | ${SimpleViewerMock.type}
        ${[RichBlobContentMock, RichBlobContentMock2]}       | ${'rich blobs with current rich blob'}       | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}    | ${RichViewerMock.type}
      `(
        'renders correct content for $description',
        async ({ snippetBlobs, currentBlob, expectedContent, activeViewerType }) => {
          createComponent({
            handler: mockDefaultHandler({ path: currentBlob.path, nodes: snippetBlobs }),
            data: { activeViewerType },
            blob: {
              ...BlobMock,
              path: currentBlob.path,
            },
          });
          await waitForPromises();

          expect(findBlobContent().props('content')).toBe(expectedContent);
        },
      );
    });

    describe('URLS with hash', () => {
      afterEach(() => {
        window.location.hash = '';
      });

      describe('if hash starts with #LC', () => {
        beforeEach(() => {
          window.location.hash = '#LC2';
        });

        it('renders simple viewer by default', async () => {
          createComponent({
            data: {},
          });
          await waitForPromises();

          expect(findBlobHeader().props('activeViewerType')).toBe(SimpleViewerMock.type);
          expect(findSimpleViewer().exists()).toBe(true);
        });

        describe('switchViewer()', () => {
          it('switches to the passed viewer', async () => {
            createComponent();
            await waitForPromises();

            findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, RichViewerMock.type);
            await waitForPromises();

            expect(findBlobHeader().props('activeViewerType')).toBe(RichViewerMock.type);
            expect(findRichViewer().exists()).toBe(true);

            findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, SimpleViewerMock.type);
            await waitForPromises();

            expect(findBlobHeader().props('activeViewerType')).toBe(SimpleViewerMock.type);
            expect(findSimpleViewer().exists()).toBe(true);
          });
        });
      });

      describe('if hash starts with anything else', () => {
        beforeEach(() => {
          window.location.hash = '#last-headline';
        });

        it('renders rich viewer by default', async () => {
          createComponent({
            data: {},
          });
          await waitForPromises();

          expect(findBlobHeader().props('activeViewerType')).toBe(RichViewerMock.type);
          expect(findRichViewer().exists()).toBe(true);
        });

        describe('switchViewer()', () => {
          it('switches to the passed viewer', async () => {
            createComponent();
            await waitForPromises();

            findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, SimpleViewerMock.type);
            await waitForPromises();

            expect(findBlobHeader().props('activeViewerType')).toBe(SimpleViewerMock.type);
            expect(findSimpleViewer().exists()).toBe(true);

            findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE, RichViewerMock.type);
            await waitForPromises();

            expect(findBlobHeader().props('activeViewerType')).toBe(RichViewerMock.type);
            expect(findRichViewer().exists()).toBe(true);
          });
        });
      });
    });
  });

  describe('functionality', () => {
    describe('render error', () => {
      it('correctly sets blob on the blob-content-error component', () => {
        createComponent();
        expect(findBlobContent().props('blob')).toEqual(BlobMock);
      });

      it(`refetches blob content on ${BLOB_RENDER_EVENT_LOAD} event`, async () => {
        createComponent();
        await waitForPromises();

        expect(requestHandlers).toHaveBeenCalledTimes(1);

        findBlobContent().vm.$emit(BLOB_RENDER_EVENT_LOAD);
        await waitForPromises();

        expect(requestHandlers).toHaveBeenCalledTimes(2);
      });

      it(`sets '${SimpleViewerMock.type}' as active on ${BLOB_RENDER_EVENT_SHOW_SOURCE} event`, () => {
        createComponent({
          data: {
            activeViewerType: RichViewerMock.type,
          },
        });

        findBlobContent().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE);
        expect(wrapper.vm.activeViewerType).toEqual(SimpleViewerMock.type);
      });
    });
  });
});
