import MockAdapter from 'axios-mock-adapter';

import projects from 'test_fixtures/api/users/projects/get.json';
import followers from 'test_fixtures/api/users/followers/get.json';
import following from 'test_fixtures/api/users/following/get.json';
import {
  getUsers,
  followUser,
  unfollowUser,
  associationsCount,
  updateUserStatus,
  getUserProjects,
  getUserFollowers,
  getUserFollowing,
} from '~/api/user_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  associationsCount as associationsCountData,
  userStatus as mockUserStatus,
} from 'jest/admin/users/mock_data';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import { timeRanges } from '~/vue_shared/constants';
import { DEFAULT_PER_PAGE } from '~/api';

describe('~/api/user_api', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    axiosMock.restore();
    axiosMock.resetHistory();
  });

  describe('getUsers', () => {
    it('calls correct URL with expected query parameters', async () => {
      const expectedUrl = '/api/v4/users.json';
      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK);

      await getUsers('den', { without_project_bots: true });

      const { url, params } = axiosMock.history.get[0];
      expect(url).toBe(expectedUrl);
      expect(params).toMatchObject({ search: 'den', without_project_bots: true });
    });
  });

  describe('followUser', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/follow';
      const expectedResponse = { message: 'Success' };

      axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

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

      axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

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

      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      await expect(associationsCount(1)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.get[0].url).toBe(expectedUrl);
    });
  });

  describe('updateUserStatus', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/user/status';
      const expectedData = {
        emoji: 'basketball',
        message: 'test',
        availability: AVAILABILITY_STATUS.BUSY,
        clear_status_after: timeRanges[0].shortcut,
      };
      const expectedResponse = { data: mockUserStatus };

      axiosMock.onPatch(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      await expect(
        updateUserStatus({
          emoji: 'basketball',
          message: 'test',
          availability: AVAILABILITY_STATUS.BUSY,
          clearStatusAfter: timeRanges[0].shortcut,
        }),
      ).resolves.toEqual(expect.objectContaining({ data: expectedResponse }));
      expect(axiosMock.history.patch[0].url).toBe(expectedUrl);
      expect(JSON.parse(axiosMock.history.patch[0].data)).toEqual(expectedData);
    });
  });

  describe('getUserProjects', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/projects';
      const expectedResponse = { data: projects };

      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      await expect(getUserProjects(1)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.get[0].url).toBe(expectedUrl);
    });
  });

  describe('getUserFollowers', () => {
    it('calls correct URL and returns expected response', async () => {
      const expectedUrl = '/api/v4/users/1/followers';
      const expectedResponse = { data: followers };
      const params = { page: 2 };

      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      await expect(getUserFollowers(1, params)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.get[0].url).toBe(expectedUrl);
      expect(axiosMock.history.get[0].params).toEqual({ ...params, per_page: DEFAULT_PER_PAGE });
    });
  });

  describe('getUserFollowing', () => {
    it('calls correct URL and returns expected response', async () => {
      const MOCK_USER_ID = 1;
      const MOCK_PAGE = 2;

      const expectedUrl = `/api/v4/users/${MOCK_USER_ID}/following`;
      const expectedResponse = { data: following };
      const params = { page: MOCK_PAGE };

      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      await expect(getUserFollowing(MOCK_USER_ID, params)).resolves.toEqual(
        expect.objectContaining({ data: expectedResponse }),
      );
      expect(axiosMock.history.get[0].url).toBe(expectedUrl);
      expect(axiosMock.history.get[0].params).toEqual({ ...params, per_page: DEFAULT_PER_PAGE });
    });
  });
});
