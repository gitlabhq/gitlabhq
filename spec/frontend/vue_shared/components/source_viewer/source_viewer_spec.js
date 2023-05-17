import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import { EVENT_ACTION, EVENT_LABEL_VIEWER } from '~/vue_shared/components/source_viewer/constants';
import Tracking from '~/tracking';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import { BLOB_DATA_MOCK, CHUNK_1, CHUNK_2, LANGUAGE_MOCK } from './mock_data';

jest.mock('~/blob/blob_links_tracking');

describe('Source Viewer component', () => {
  let wrapper;
  const CHUNKS_MOCK = [CHUNK_1, CHUNK_2];

  const createComponent = () => {
    wrapper = shallowMountExtended(SourceViewer, {
      propsData: { blob: BLOB_DATA_MOCK, chunks: CHUNKS_MOCK },
    });
  };

  const findChunks = () => wrapper.findAllComponents(Chunk);

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    return createComponent();
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
});
