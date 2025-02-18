import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import { discussionMock } from 'jest/notes/mock_data';
import { INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import { ADD_OR_UPDATE_DISCUSSIONS } from '~/notes/stores/mutation_types';
import { SET_DIFF_DATA_BATCH, SET_LINE_DISCUSSIONS_FOR_FILE } from '~/diffs/store/mutation_types';
import { getDiffPositionByLineCode } from '~/diffs/store/utils';
import mutationTypes from '~/mr_notes/stores/mutation_types';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';

describe('Legacy MR Notes', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false, plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    store = useMrNotes();
  });

  describe('actions', () => {
    describe('setEndpoints', () => {
      it('sets endpoints', () => {
        const endpoints = { endpointA: 'a' };

        store.setEndpoints(endpoints);

        expect(store.endpoints).toEqual(endpoints);
      });
    });

    describe('fetchMrMetadata', () => {
      const mrMetadata = { meta: true, data: 'foo' };
      const metadata = 'metadata';
      const endpoints = { metadata };
      let mock;

      beforeEach(async () => {
        await store.setEndpoints(endpoints);

        mock = new MockAdapter(axios);

        mock.onGet(metadata).reply(HTTP_STATUS_OK, mrMetadata);
      });

      afterEach(() => {
        mock.restore();
      });

      it('should fetch the data from the API', async () => {
        await store.fetchMrMetadata();

        await axios.waitForAll();

        expect(mock.history.get).toHaveLength(1);
        expect(mock.history.get[0].url).toBe(metadata);
      });

      it('should set the fetched data into state', async () => {
        await store.fetchMrMetadata();

        expect(store.mrMetadata).toEqual(mrMetadata);
      });

      it('should set failedToLoadMetadata flag when request fails', async () => {
        mock.onGet(metadata).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await store.fetchMrMetadata();

        expect(store.failedToLoadMetadata).toBe(true);
      });
    });

    describe('toggleAllVisibleDiscussions', () => {
      beforeEach(() => {
        const diff = getDiffFileMock();
        const discussion = {
          ...discussionMock,
          diff_file: diff,
          line_code: diff[INLINE_DIFF_LINES_KEY][0].line_code,
        };
        useNotes()[ADD_OR_UPDATE_DISCUSSIONS]([discussion]);
        useLegacyDiffs()[SET_DIFF_DATA_BATCH]({ diff_files: [diff] });
        useLegacyDiffs()[SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode: getDiffPositionByLineCode(useLegacyDiffs().diffFiles),
          hash: diff.file_hash,
        });
      });

      it('dispatches toggleAllDiscussions', () => {
        const mock = useNotes().toggleAllDiscussions.mockImplementationOnce();
        store.toggleAllVisibleDiscussions();
        expect(mock).toHaveBeenCalled();
      });

      it('dispatches toggleAllDiffDiscussions when on diffs page', () => {
        const mock = useLegacyDiffs().toggleAllDiffDiscussions.mockImplementationOnce();
        store[mutationTypes.SET_ACTIVE_TAB]('diffs');
        store.toggleAllVisibleDiscussions();
        expect(mock).toHaveBeenCalled();
      });
    });

    describe(mutationTypes.SET_ENDPOINTS, () => {
      it('should set the endpoints value', () => {
        const endpoints = { endpointA: 'A', endpointB: 'B' };

        store[mutationTypes.SET_ENDPOINTS](endpoints);

        expect(store.endpoints).toEqual(endpoints);
      });
    });

    describe(mutationTypes.SET_MR_METADATA, () => {
      it('store the provided MR Metadata in the state', () => {
        const metadata = { propA: 'A', propB: 'B' };

        store[mutationTypes.SET_MR_METADATA](metadata);

        expect(store.mrMetadata.propA).toBe('A');
        expect(store.mrMetadata.propB).toBe('B');
      });
    });
  });
});
