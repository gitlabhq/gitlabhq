import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createStore } from '~/mr_notes/stores';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import { SET_DIFF_DATA_BATCH, SET_LINE_DISCUSSIONS_FOR_FILE } from '~/diffs/store/mutation_types';
import { discussionMock } from 'jest/notes/mock_data';
import { getDiffPositionByLineCode } from '~/diffs/store/utils';
import { INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import { ADD_OR_UPDATE_DISCUSSIONS } from '~/notes/stores/mutation_types';
import mutationTypes from '~/mr_notes/stores/mutation_types';

describe('MR Notes Mutator Actions', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('setEndpoints', () => {
    it('sets endpoints', async () => {
      const endpoints = { endpointA: 'a' };

      await store.dispatch('setEndpoints', endpoints);

      expect(store.state.page.endpoints).toEqual(endpoints);
    });
  });

  describe('fetchMrMetadata', () => {
    const mrMetadata = { meta: true, data: 'foo' };
    const metadata = 'metadata';
    const endpoints = { metadata };
    let mock;

    beforeEach(async () => {
      await store.dispatch('setEndpoints', endpoints);

      mock = new MockAdapter(axios);

      mock.onGet(metadata).reply(HTTP_STATUS_OK, mrMetadata);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should fetch the data from the API', async () => {
      await store.dispatch('fetchMrMetadata');

      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(metadata);
    });

    it('should set the fetched data into state', async () => {
      await store.dispatch('fetchMrMetadata');

      expect(store.state.page.mrMetadata).toEqual(mrMetadata);
    });

    it('should set failedToLoadMetadata flag when request fails', async () => {
      mock.onGet(metadata).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await store.dispatch('fetchMrMetadata');

      expect(store.state.page.failedToLoadMetadata).toBe(true);
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
      store.commit(ADD_OR_UPDATE_DISCUSSIONS, [discussion]);
      store.commit(`diffs/${SET_DIFF_DATA_BATCH}`, { diff_files: [diff] });
      store.commit(`diffs/${SET_LINE_DISCUSSIONS_FOR_FILE}`, {
        discussion,
        diffPositionByLineCode: getDiffPositionByLineCode(store.state.diffs.diffFiles),
        hash: diff.file_hash,
      });
    });

    it('dispatches toggleAllDiscussions', async () => {
      expect(store.state.notes.discussions[0].expanded).toEqual(true);

      await store.dispatch('toggleAllVisibleDiscussions');

      expect(store.state.notes.discussions[0].expanded).toEqual(false);
    });

    it('dispatches toggleAllDiffDiscussions when on diffs page', async () => {
      store.commit(mutationTypes.SET_ACTIVE_TAB, 'diffs');

      expect(store.state.diffs.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toEqual(
        true,
      );

      await store.dispatch('toggleAllVisibleDiscussions');

      expect(store.state.diffs.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toEqual(
        false,
      );
    });
  });
});
