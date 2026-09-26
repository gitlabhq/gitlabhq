import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  CODEOWNERS_FILE_NAME,
} from '~/vue_shared/components/source_viewer/constants';
import * as urlUtility from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import LineHighlighter from '~/blob/line_highlighter';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import blameDataQuery from '~/vue_shared/components/source_viewer/queries/blame_data.query.graphql';
import BlameColumnResizer from '~/vue_shared/components/source_viewer/components/blame_column_resizer.vue';
import CodeownersValidation from 'ee_component/blob/components/codeowners_validation.vue';

import {
  BLOB_DATA_MOCK,
  CHUNK_1,
  CHUNK_2,
  CHUNK_3,
  LANGUAGE_MOCK,
  BLAME_DATA_QUERY_RESPONSE_MOCK,
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
  const findFileContent = () => wrapper.findByTestId('blob-viewer-file-content');
  const findColumnResizer = () => wrapper.findComponent(BlameColumnResizer);
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

    it('hides the blame gutter if showBlame changes to false', async () => {
      await triggerChunkAppear();
      expect(findChunks().at(0).props('blameGroups')).toHaveLength(1);

      await wrapper.setProps({ showBlame: false });
      await nextTick();

      expect(findChunks().at(0).props('isBlameActive')).toBe(false);
      expect(findChunks().at(0).props('blameGroups')).toHaveLength(0);
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
    describe('Blame information', () => {
      it('passes the blame groups covering a chunk to that chunk', async () => {
        await triggerChunkAppear();

        expect(findChunks().at(0).props()).toMatchObject({
          isBlameActive: true,
        });
        expect(findChunks().at(0).props('blameGroups')).toEqual([
          expect.objectContaining({ commit: blameInfo[0].commit }),
        ]);
      });

      it('positions blame groups by grid row instead of a measured offset', async () => {
        await triggerChunkAppear();

        // The mocked group starts at line 1 and spans 3 lines. Opening the file,
        // it takes no separator.
        expect(findChunks().at(0).props('blameGroups')).toEqual([
          expect.objectContaining({ rowStart: 1, rowSpan: 3, hasSeparator: false }),
        ]);
      });

      it('does not hand a chunk a new blame groups array when its blame is unchanged', async () => {
        await triggerChunkAppear(0);
        const groups = findChunks().at(0).props('blameGroups');

        // Chunk 1 appearing refetches chunk 0 as well, so chunk 0's blame is
        // rebuilt from data it already had. Its prop must keep its identity, or
        // every appeared chunk re-renders on every blame arrival.
        await triggerChunkAppear(1);

        expect(findChunks().at(0).props('blameGroups')).toBe(groups);
      });

      it('gives a chunk with no blame data no groups', async () => {
        await triggerChunkAppear(0);

        expect(findChunks().at(1).props('blameGroups')).toEqual([]);
      });

      it('declares the shared blame column once so chunks can align to it', async () => {
        await triggerChunkAppear();

        expect(findFileContent().attributes('style')).toContain(
          'grid-template-columns: 400px auto 1fr',
        );
      });

      it('marks a chunk as loading only while its blame request is in flight', async () => {
        findChunks().at(0).vm.$emit('appear');
        await nextTick();

        expect(findChunks().at(0).props('isBlameLoading')).toBe(true);

        await waitForPromises();

        expect(findChunks().at(0).props('isBlameLoading')).toBe(false);
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

      it('loads blame for all already-visible chunks when showBlame is enabled', async () => {
        createComponent({ showBlame: false });
        await triggerChunkAppear(0);
        await triggerChunkAppear(1);
        blameDataQueryHandlerSuccess.mockClear();

        await wrapper.setProps({ showBlame: true });
        await waitForPromises();

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(2);
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 1, toLine: 70 }),
        );
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 71, toLine: 110 }),
        );
      });

      it('preloads blame for all already-visible chunks when shouldPreloadBlame is enabled', async () => {
        createComponent({ showBlame: false, shouldPreloadBlame: false });
        await triggerChunkAppear(0);
        await triggerChunkAppear(1);
        blameDataQueryHandlerSuccess.mockClear();

        await wrapper.setProps({ shouldPreloadBlame: true });
        await waitForPromises();

        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(2);
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 1, toLine: 70 }),
        );
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({ fromLine: 71, toLine: 110 }),
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
        // The debounce mock is synchronous by default, which would process the
        // chunk on `appear` and leave nothing for `disappear` to cancel. Give it a
        // real timeout so the queue can actually be drained late.
        beforeEach(() => {
          global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
        });

        afterEach(() => {
          global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
        });

        it('does not fetch blame data when chunk disappears before processing', () => {
          blameDataQueryHandlerSuccess.mockClear();

          findChunks().at(0).vm.$emit('appear');
          findChunks().at(0).vm.$emit('disappear');

          jest.runAllTimers();

          expect(blameDataQueryHandlerSuccess).not.toHaveBeenCalled();
        });

        it('fetches blame data for a chunk that stays visible', () => {
          blameDataQueryHandlerSuccess.mockClear();

          findChunks().at(0).vm.$emit('appear');

          jest.runAllTimers();

          expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(1);
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

      it('does not activate the blame gutter when `showBlame: false`', async () => {
        createComponent({ showBlame: false });
        await triggerChunkAppear();

        expect(findChunks().at(0).props('isBlameActive')).toBe(false);
        expect(findChunks().at(0).props('blameGroups')).toEqual([]);
      });

      it('treats a response carrying no blame groups as empty, not as a failure', async () => {
        createAlert.mockClear();
        const noGroups = jest.fn().mockResolvedValue({
          data: { project: { id: '1', repository: { blobs: { nodes: [] } } } },
        });
        createComponent({ blameQueryHandler: noGroups });
        await triggerChunkAppear();

        expect(createAlert).not.toHaveBeenCalled();
        expect(findChunks().at(0).props('blameGroups')).toEqual([]);
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

  describe('blame column resizer', () => {
    const findBlameColumnWidth = () =>
      findFileContent()
        .attributes('style')
        .match(/grid-template-columns: (\S+)/)[1];

    it('mounts the resizer', () => {
      expect(findColumnResizer().exists()).toBe(true);
    });

    it('feeds the resizer width into the shared blame column', async () => {
      expect(findBlameColumnWidth()).toBe('400px');

      findColumnResizer().vm.$emit('input', 520);
      await nextTick();

      expect(findBlameColumnWidth()).toBe('520px');
    });

    describe('when showBlame is false', () => {
      beforeEach(() => createComponent({ showBlame: false }));

      it('does not mount the resizer', () => {
        expect(findColumnResizer().exists()).toBe(false);
      });

      it('collapses the blame column', () => {
        expect(findBlameColumnWidth()).toBe('0');
      });
    });
  });

  describe('horizontal scrollbar', () => {
    const findScrollbar = () => wrapper.findByTestId('horizontal-scrollbar');
    const findScrollbarTrack = () => wrapper.findByTestId('horizontal-scrollbar-track');

    const setContentDimensions = ({ scrollWidth, clientWidth }) => {
      const { element } = findFileContent();
      Object.defineProperty(element, 'scrollWidth', { value: scrollWidth, configurable: true });
      Object.defineProperty(element, 'clientWidth', { value: clientWidth, configurable: true });
    };

    // jsdom has no layout, so an own writable property is needed to shadow the
    // prototype accessor and let an assignment stick.
    const stubScrollLeft = (element, value = 0) =>
      Object.defineProperty(element, 'scrollLeft', { value, writable: true, configurable: true });

    // The chunk list is replaced once the whole file is chunked, which is when
    // the widest line, and so the scrollable width, can change.
    const replaceChunks = async (chunks) => {
      await wrapper.setProps({ chunks });
      await waitForPromises();
    };

    it('makes the content keyboard focusable with an accessible name', () => {
      expect(findFileContent().attributes()).toMatchObject({
        role: 'region',
        'aria-label': 'File contents',
        tabindex: '0',
      });
    });

    it('is not rendered when the content fits', () => {
      expect(findScrollbar().exists()).toBe(false);
    });

    describe('when the content is wider than the viewport', () => {
      beforeEach(async () => {
        setContentDimensions({ scrollWidth: 2000, clientWidth: 800 });
        await replaceChunks([CHUNK_1, CHUNK_2, CHUNK_3]);
      });

      it('renders the scrollbar', () => {
        expect(findScrollbar().exists()).toBe(true);
      });

      it('keeps the scrollbar out of the tab order and accessibility tree', () => {
        expect(findScrollbar().attributes()).toMatchObject({
          'aria-hidden': 'true',
          tabindex: '-1',
        });
      });

      it('sizes the track to the scrollable width', () => {
        expect(findScrollbarTrack().attributes('style')).toBe('width: 2000px;');
      });

      it('scrolls the content when the scrollbar is scrolled', () => {
        const { element } = findFileContent();
        stubScrollLeft(element);
        stubScrollLeft(findScrollbar().element, 350);

        findScrollbar().trigger('scroll');

        expect(element.scrollLeft).toBe(350);
      });

      it('follows the content when the content is scrolled', () => {
        const scrollbar = findScrollbar().element;
        stubScrollLeft(scrollbar);
        stubScrollLeft(findFileContent().element, 420);

        findFileContent().trigger('scroll');

        expect(scrollbar.scrollLeft).toBe(420);
      });

      it('re-measures when the blame column is resized', async () => {
        setContentDimensions({ scrollWidth: 2400, clientWidth: 800 });
        findColumnResizer().vm.$emit('input', 520);
        await waitForPromises();

        expect(findScrollbarTrack().attributes('style')).toBe('width: 2400px;');
      });

      it('re-measures when blame is toggled off', async () => {
        setContentDimensions({ scrollWidth: 800, clientWidth: 800 });
        await wrapper.setProps({ showBlame: false });
        await waitForPromises();

        expect(findScrollbar().exists()).toBe(false);
      });

      describe('while the blame column is being dragged', () => {
        beforeEach(() => {
          global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
        });

        afterEach(() => {
          global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
        });

        it('waits for the drag to settle before re-measuring', async () => {
          setContentDimensions({ scrollWidth: 2400, clientWidth: 800 });
          [450, 500, 520].forEach((width) => findColumnResizer().vm.$emit('input', width));
          await waitForPromises();

          expect(findScrollbarTrack().attributes('style')).toBe('width: 2000px;');

          jest.runAllTimers();
          await waitForPromises();

          expect(findScrollbarTrack().attributes('style')).toBe('width: 2400px;');
        });
      });

      it('stops rendering once the content fits again', async () => {
        setContentDimensions({ scrollWidth: 800, clientWidth: 800 });
        await replaceChunks([CHUNK_1]);

        expect(findScrollbar().exists()).toBe(false);
      });
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
      await waitForPromises();
      expect(findCodeownersValidation().exists()).toBe(true);
    });
  });
});
