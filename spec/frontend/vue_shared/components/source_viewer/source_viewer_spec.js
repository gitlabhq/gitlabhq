import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture } from 'helpers/fixtures';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  CODEOWNERS_FILE_NAME,
} from '~/vue_shared/components/source_viewer/constants';
import * as urlUtility from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import LineHighlighter from '~/blob/line_highlighter';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import blameDataQuery from '~/vue_shared/components/source_viewer/queries/blame_data.query.graphql';
import Blame from '~/vue_shared/components/source_viewer/components/blame_info.vue';
import BlameSkeletonLoader from '~/vue_shared/components/source_viewer/components/blame_skeleton_loader.vue';
import * as utils from '~/vue_shared/components/source_viewer/utils';
import CodeownersValidation from 'ee_component/blob/components/codeowners_validation.vue';

import {
  BLOB_DATA_MOCK,
  CHUNK_1,
  CHUNK_2,
  CHUNK_3,
  LANGUAGE_MOCK,
  BLAME_DATA_QUERY_RESPONSE_MOCK,
  SOURCE_CODE_CONTENT_MOCK,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const lineHighlighter = new LineHighlighter();
jest.mock('~/blob/line_highlighter', () =>
  jest.fn().mockReturnValue({
    highlightHash: jest.fn(),
  }),
);
jest.mock('~/blob/blob_links_tracking');

describe('Source Viewer component', () => {
  let wrapper;
  let fakeApollo;
  const CHUNKS_MOCK = [CHUNK_1, CHUNK_2];
  const projectPath = 'test';
  const currentRef = 'main';
  const hash = '#L142';

  const blameDataQueryHandlerSuccess = jest.fn().mockResolvedValue(BLAME_DATA_QUERY_RESPONSE_MOCK);
  const blameDataQueryHandlerError = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const blameInfo =
    BLAME_DATA_QUERY_RESPONSE_MOCK.data.project.repository.blobs.nodes[0].blame.groups;

  const createComponent = ({
    showBlame = true,
    shouldPreloadBlame = false,
    blob = {},
    blameQueryHandler = blameDataQueryHandlerSuccess,
  } = {}) => {
    fakeApollo = createMockApollo([[blameDataQuery, blameQueryHandler]]);

    wrapper = shallowMountExtended(SourceViewer, {
      apolloProvider: fakeApollo,
      mocks: { $route: { hash } },
      propsData: {
        blob: { ...blob, ...BLOB_DATA_MOCK },
        chunks: CHUNKS_MOCK,
        projectPath,
        currentRef,
        shouldPreloadBlame,
        showBlame,
      },
    });
  };

  const findChunks = () => wrapper.findAllComponents(Chunk);
  const findBlameComponents = () => wrapper.findAllComponents(Blame);
  const findBlameSkeletonLoaders = () => wrapper.findAllComponents(BlameSkeletonLoader);
  const triggerChunkAppear = async (chunkIndex = 0) => {
    findChunks().at(chunkIndex).vm.$emit('appear');
    await waitForPromises();
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue('true');
    return createComponent();
  });

  it('instantiates the lineHighlighter class', () => {
    expect(LineHighlighter).toHaveBeenCalled();
  });

  describe('when mounted', () => {
    it('should highlight the hash', () => {
      expect(lineHighlighter.highlightHash).toHaveBeenCalledWith(hash);
    });

    it('hides the blame viewer if showBlame changes to false', async () => {
      await triggerChunkAppear();
      expect(findBlameComponents()).toHaveLength(1);

      await wrapper.setProps({ showBlame: false });
      await nextTick();

      expect(findBlameComponents()).toHaveLength(0);
    });
  });

  describe('event tracking', () => {
    it('fires a tracking event when the component is created', () => {
      const eventData = { label: EVENT_LABEL_VIEWER, property: LANGUAGE_MOCK };
      expect(Tracking.event).toHaveBeenCalledWith(undefined, EVENT_ACTION, eventData);
    });

    it('adds blob links tracking', () => {
      expect(addBlobLinksTracking).toHaveBeenCalled();
    });
  });

  describe('rendering', () => {
    describe('DOM updates', () => {
      it('adds the necessary classes to the DOM', async () => {
        setHTMLFixture(SOURCE_CODE_CONTENT_MOCK);
        jest.spyOn(utils, 'toggleBlameLineBorders');
        createComponent();
        await triggerChunkAppear();
        expect(utils.toggleBlameLineBorders).toHaveBeenCalledWith(blameInfo, true);
      });
    });

    describe('Blame information', () => {
      it('renders a Blame component when a chunk appears', async () => {
        await triggerChunkAppear();

        expect(findBlameComponents().at(0).exists()).toBe(true);
        expect(findBlameComponents().at(0).props()).toMatchObject({
          blameInfo,
          projectPath,
        });
      });

      describe('per-chunk skeleton loaders', () => {
        const emitAppear = () => findChunks().at(0).vm.$emit('appear');

        it.each([
          { showBlame: true, minCount: 1 },
          { showBlame: false, minCount: 0 },
        ])(
          'shows skeleton loaders when showBlame is $showBlame',
          async ({ showBlame, minCount }) => {
            createComponent({ showBlame });
            emitAppear();
            await nextTick();
            expect(findBlameSkeletonLoaders().length).toBeGreaterThanOrEqual(minCount);
          },
        );

        it('removes skeleton loader after data loads', async () => {
          createComponent();
          await triggerChunkAppear(0);
          expect(findBlameSkeletonLoaders()).toHaveLength(0);
        });

        it('positions skeleton loader at chunk offset', async () => {
          createComponent();
          emitAppear();
          await nextTick();

          const chunkOffset = findChunks().at(0).element.offsetTop;
          expect(findBlameSkeletonLoaders().at(0)?.attributes('style')).toContain(
            `transform: translateY(${chunkOffset}px)`,
          );
        });

        it('passes totalLines from the chunk to the skeleton loader', async () => {
          createComponent();
          emitAppear();
          await nextTick();

          const loader = findBlameSkeletonLoaders().at(0);
          expect(loader.props('totalLines')).toBe(1);
        });
      });

      it('preloads blame data', async () => {
        createComponent({ showBlame: false, shouldPreloadBlame: true });
        await triggerChunkAppear();

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({
            filePath: BLOB_DATA_MOCK.path,
            fullPath: projectPath,
            ref: currentRef,
          }),
        );
      });

      it('calls the blame data query', async () => {
        await triggerChunkAppear();

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({
            filePath: BLOB_DATA_MOCK.path,
            fullPath: projectPath,
            ref: currentRef,
            ignoreRevs: true,
          }),
        );
      });

      it('calls the query only once per chunk', async () => {
        // We trigger the `appear` event multiple times here in order to simulate the user scrolling past the chunk more than once.
        // In this scenario we only want to query the backend once.
        await triggerChunkAppear();
        await triggerChunkAppear();

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(1);
      });

      describe('chunk visibility queuing', () => {
        it('does not fetch blame data when chunk disappears before processing', () => {
          blameDataQueryHandlerSuccess.mockClear();

          triggerChunkAppear(0);
          findChunks().at(0).vm.$emit('disappear');

          jest.runAllTimers();

          expect(blameDataQueryHandlerSuccess).not.toHaveBeenCalled();
        });
      });

      it('requests blame information for overlapping chunk', async () => {
        await triggerChunkAppear(1);

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(2);
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 71, toLine: 110 }),
        );
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 1, toLine: 70 }),
        );

        expect(findChunks().at(0).props('isHighlighted')).toBe(true);
      });

      it('does not render a Blame component when `showBlame: false`', async () => {
        createComponent({ showBlame: false });
        await triggerChunkAppear();

        expect(findBlameComponents()).toHaveLength(0);
      });

      it('shows error alert when blame query fails', async () => {
        createAlert.mockClear();
        createComponent({ blameQueryHandler: blameDataQueryHandlerError });
        await triggerChunkAppear();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Unable to load blame information. Please try again.',
          parent: expect.any(HTMLElement),
          dismissible: false,
          captureError: true,
          error: expect.any(Error),
        });
      });

      it('shows backend error message when GraphQL error has message', async () => {
        const backendErrorMessage = 'Error message from backend.';
        const graphQLError = {
          graphQLErrors: [{ message: backendErrorMessage }],
        };
        const blameDataQueryHandlerWithGraphQLError = jest.fn().mockRejectedValue(graphQLError);

        createAlert.mockClear();
        createComponent({ blameQueryHandler: blameDataQueryHandlerWithGraphQLError });
        await triggerChunkAppear();

        expect(createAlert).toHaveBeenCalledWith({
          message: backendErrorMessage,
          parent: expect.any(HTMLElement),
          dismissible: false,
          captureError: true,
          error: graphQLError,
        });
      });
    });

    it('renders a Chunk component for each chunk', () => {
      expect(findChunks().at(0).props()).toMatchObject(CHUNK_1);
      expect(findChunks().at(1).props()).toMatchObject(CHUNK_2);
    });
  });

  describe('hash highlighting', () => {
    it('calls highlightHash with expected parameter once the watcher for chunks is triggered', async () => {
      // manually setting the value here to trigger the watch
      await wrapper.setProps({ chunks: [CHUNK_1, CHUNK_2, CHUNK_3] });
      await nextTick();
      expect(lineHighlighter.highlightHash).toHaveBeenCalledWith(hash);
    });
  });

  describe('Codeowners validation', () => {
    const findCodeownersValidation = () => wrapper.findComponent(CodeownersValidation);

    it('does not render codeowners validation when file is not CODEOWNERS', async () => {
      await createComponent();
      await nextTick();
      expect(findCodeownersValidation().exists()).toBe(false);
    });

    it('renders codeowners validation when file is CODEOWNERS', async () => {
      await createComponent({ blob: { name: CODEOWNERS_FILE_NAME } });
      await nextTick();
      expect(findCodeownersValidation().exists()).toBe(true);
    });
  });
});
