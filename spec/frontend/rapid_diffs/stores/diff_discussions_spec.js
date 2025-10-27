import AxiosMockAdapter from 'axios-mock-adapter';
import { createPinia, setActivePinia } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

describe('diffDiscussions store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  describe('fetchDiscussions', () => {
    it('fetches', async () => {
      const url = '/discussions';
      const discussions = [{ id: 'abc' }];
      const adapter = new AxiosMockAdapter(axios);
      adapter.onGet(url).reply(HTTP_STATUS_OK, { discussions });
      await useDiffDiscussions().fetchDiscussions(url);
      expect(useDiffDiscussions().discussions).toStrictEqual(discussions);
    });
  });

  describe('getDiscussionById', () => {
    it('returns discussion', () => {
      const targetDiscussion = { id: 'efg' };
      useDiffDiscussions().discussions = [{ id: 'abc' }, targetDiscussion];
      expect(useDiffDiscussions().getDiscussionById(targetDiscussion.id)).toStrictEqual(
        targetDiscussion,
      );
    });
  });
});
