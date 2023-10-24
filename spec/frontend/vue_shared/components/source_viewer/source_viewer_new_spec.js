import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer_new.vue';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk_new.vue';
import { EVENT_ACTION, EVENT_LABEL_VIEWER } from '~/vue_shared/components/source_viewer/constants';
import Tracking from '~/tracking';
import LineHighlighter from '~/blob/line_highlighter';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import waitForPromises from 'helpers/wait_for_promises';
import blameDataQuery from '~/vue_shared/components/source_viewer/queries/blame_data.query.graphql';
import Blame from '~/vue_shared/components/source_viewer/components/blame_info.vue';

import {
  BLOB_DATA_MOCK,
  CHUNK_1,
  CHUNK_2,
  LANGUAGE_MOCK,
  BLAME_DATA_QUERY_RESPONSE_MOCK,
} from './mock_data';

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
  const hash = '#L142';

  const blameDataQueryHandlerSuccess = jest.fn().mockResolvedValue(BLAME_DATA_QUERY_RESPONSE_MOCK);

  const createComponent = ({ showBlame = true } = {}) => {
    fakeApollo = createMockApollo([[blameDataQuery, blameDataQueryHandlerSuccess]]);

    wrapper = shallowMountExtended(SourceViewer, {
      apolloProvider: fakeApollo,
      mocks: { $route: { hash } },
      propsData: {
        blob: BLOB_DATA_MOCK,
        chunks: CHUNKS_MOCK,
        projectPath: 'test',
        showBlame,
      },
    });
  };

  const findChunks = () => wrapper.findAllComponents(Chunk);
  const findBlameComponents = () => wrapper.findAllComponents(Blame);

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    return createComponent();
  });

  it('instantiates the lineHighlighter class', () => {
    expect(LineHighlighter).toHaveBeenCalled();
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
    it('does not render a Blame component if the respective chunk for the blame has not appeared', async () => {
      await waitForPromises();
      expect(findBlameComponents()).toHaveLength(0);
    });

    describe('Blame information', () => {
      const triggerChunkAppear = async () => {
        findChunks().at(0).vm.$emit('appear');
        await waitForPromises();
      };
      beforeEach(async () => {});

      it('renders a Blame component when a chunk appears', async () => {
        await triggerChunkAppear();
        const blameData =
          BLAME_DATA_QUERY_RESPONSE_MOCK.data.project.repository.blobs.nodes[0].blame.groups;

        expect(findBlameComponents().at(0).exists()).toBe(true);
        expect(findBlameComponents().at(0).props()).toMatchObject({ blameData });
      });

      it('calls the query only once per chunk', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'query');

        // We trigger the `appear` event multiple times here in order to simulate the user scrolling past the chunk more than once.
        // In this scenario we only want to query the backend once.
        await triggerChunkAppear();
        await triggerChunkAppear();

        expect(wrapper.vm.$apollo.query).toHaveBeenCalledTimes(1);
      });

      it('does not render a Blame component when `showBlame: false`', async () => {
        createComponent({ showBlame: false });
        await triggerChunkAppear();

        expect(findBlameComponents()).toHaveLength(0);
      });
    });

    it('renders a Chunk component for each chunk', () => {
      expect(findChunks().at(0).props()).toMatchObject(CHUNK_1);
      expect(findChunks().at(1).props()).toMatchObject(CHUNK_2);
    });
  });

  describe('hash highlighting', () => {
    it('calls highlightHash with expected parameter', () => {
      const scrollEnabled = false;
      expect(lineHighlighter.highlightHash).toHaveBeenCalledWith(hash, scrollEnabled);
    });
  });
});
