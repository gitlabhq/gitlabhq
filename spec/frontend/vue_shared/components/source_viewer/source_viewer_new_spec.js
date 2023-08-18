import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer_new.vue';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk_new.vue';
import { EVENT_ACTION, EVENT_LABEL_VIEWER } from '~/vue_shared/components/source_viewer/constants';
import Tracking from '~/tracking';
import LineHighlighter from '~/blob/line_highlighter';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import { BLOB_DATA_MOCK, CHUNK_1, CHUNK_2, LANGUAGE_MOCK } from './mock_data';

const lineHighlighter = new LineHighlighter();
jest.mock('~/blob/line_highlighter', () =>
  jest.fn().mockReturnValue({
    highlightHash: jest.fn(),
  }),
);
jest.mock('~/blob/blob_links_tracking');

describe('Source Viewer component', () => {
  let wrapper;
  const CHUNKS_MOCK = [CHUNK_1, CHUNK_2];
  const hash = '#L142';

  const createComponent = () => {
    wrapper = shallowMountExtended(SourceViewer, {
      mocks: { $route: { hash } },
      propsData: { blob: BLOB_DATA_MOCK, chunks: CHUNKS_MOCK },
    });
  };

  const findChunks = () => wrapper.findAllComponents(Chunk);

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
    it('renders a Chunk component for each chunk', () => {
      expect(findChunks().at(0).props()).toMatchObject(CHUNK_1);
      expect(findChunks().at(1).props()).toMatchObject(CHUNK_2);
    });
  });

  describe('hash highlighting', () => {
    it('calls highlightHash with expected parameter', () => {
      expect(lineHighlighter.highlightHash).toHaveBeenCalledWith(hash);
    });
  });
});
