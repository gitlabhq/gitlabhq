import MockAdapter from 'axios-mock-adapter';

import { followUser, unfollowUser, associationsCount } from '~/api/user_api';
import axios from '~/lib/utils/axios_utils';
import { associationsCount as associationsCountData } from 'jest/admin/users/mock_data';

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

  describe('associationsCount', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/associations_count';
      const expectedResponse = { data: associationsCountData };

      axiosMock.onGet(expectedUrl).replyOnce(200, expectedResponse);

      await expect(associationsCount(1)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.get[0].url).toBe(expectedUrl);
    });
  });
});
