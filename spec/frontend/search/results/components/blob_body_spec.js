import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobChunks from '~/search/results/components/blob_chunks.vue';
import ZoektBlobResultsChunks from '~/search/results/components/blob_body.vue';
import eventHub from '~/search/results/event_hub';
import { mockDataForBlobBody } from '../../mock_data';

describe('BlobChunks', () => {
  let wrapper;

  const createComponent = (file = {}) => {
    wrapper = shallowMountExtended(ZoektBlobResultsChunks, {
      propsData: {
        file,
        position: 1,
        systemColorScheme: 'gl-light',
      },
    });
  };

  const findBlobChunks = () => wrapper.findAllComponents(BlobChunks);

  describe('component basics', () => {
    beforeEach(() => {
      createComponent(mockDataForBlobBody);
    });

    it(`renders default amount of chunks`, () => {
      expect(findBlobChunks()).toHaveLength(3);
      expect(findBlobChunks().at(0).props()).toMatchObject({
        chunk: {
          lines: expect.any(Array),
          matchCountInChunk: expect.any(Number),
          __typename: expect.any(String),
        },
        blameLink: 'blame/test.js',
        fileUrl: 'https://gitlab.com/file/test.js',
        position: 1,
      });
    });

    it(`renders all chunks`, async () => {
      eventHub.$emit('showMore', { id: 'Testjs/Test:file/test.js', state: true });
      await nextTick();
      expect(findBlobChunks()).toHaveLength(4);
    });
  });
});
