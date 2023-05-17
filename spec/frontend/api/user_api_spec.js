import MockAdapter from 'axios-mock-adapter';

import projects from 'test_fixtures/api/users/projects/get.json';
import {
  followUser,
  unfollowUser,
  associationsCount,
  updateUserStatus,
  getUserProjects,
} from '~/api/user_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  associationsCount as associationsCountData,
  userStatus as mockUserStatus,
} from 'jest/admin/users/mock_data';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import { timeRanges } from '~/vue_shared/constants';

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
});
