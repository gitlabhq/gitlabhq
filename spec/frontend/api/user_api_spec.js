import MockAdapter from 'axios-mock-adapter';

import { followUser, unfollowUser } from '~/api/user_api';
import axios from '~/lib/utils/axios_utils';

describe('~/api/user_api', () => {
  let axiosMock;
  let originalGon;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    originalGon = window.gon;
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    axiosMock.restore();
    axiosMock.resetHistory();
    window.gon = originalGon;
  });

  describe('followUser', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/follow';
      const expectedResponse = { message: 'Success' };

      axiosMock.onPost(expectedUrl).replyOnce(200, expectedResponse);

      await expect(followUser(1)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.post[0].url).toBe(expectedUrl);
    });
  });

  describe('unfollowUser', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/unfollow';
      const expectedResponse = { message: 'Success' };

      axiosMock.onPost(expectedUrl).replyOnce(200, expectedResponse);

      await expect(unfollowUser(1)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.post[0].url).toBe(expectedUrl);
    });
  });
});
