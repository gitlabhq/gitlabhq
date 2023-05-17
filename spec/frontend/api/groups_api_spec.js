import MockAdapter from 'axios-mock-adapter';
import getGroupTransferLocationsResponse from 'test_fixtures/api/groups/transfer_locations.json';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_PER_PAGE } from '~/api';
import { updateGroup, getGroupTransferLocations, getGroupMembers } from '~/api/groups_api';

const mockApiVersion = 'v4';
const mockUrlRoot = '/gitlab';
const mockGroupId = '99';

describe('GroupsApi', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = {
      api_version: mockApiVersion,
      relative_url_root: mockUrlRoot,
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('updateGroup', () => {
    const mockData = { attr: 'value' };
    const expectedUrl = `${mockUrlRoot}/api/${mockApiVersion}/groups/${mockGroupId}`;

    beforeEach(() => {
      mock.onPut(expectedUrl).reply(({ data }) => {
        return [HTTP_STATUS_OK, { id: mockGroupId, ...JSON.parse(data) }];
      });
    });

    it('updates group', async () => {
      const res = await updateGroup(mockGroupId, mockData);

      expect(res.data).toMatchObject({ id: mockGroupId, ...mockData });
    });
  });

  describe('getGroupTransferLocations', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    it('retrieves transfer locations from the correct URL and returns them in the response data', async () => {
      const params = { page: 1 };
      const expectedUrl = `${mockUrlRoot}/api/${mockApiVersion}/groups/${mockGroupId}/transfer_locations`;

      mock
        .onGet(expectedUrl)
        .replyOnce(HTTP_STATUS_OK, { data: getGroupTransferLocationsResponse });

      await expect(getGroupTransferLocations(mockGroupId, params)).resolves.toMatchObject({
        data: { data: getGroupTransferLocationsResponse },
      });

      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { ...params, per_page: DEFAULT_PER_PAGE },
      });
    });
  });

  describe('getGroupMembers', () => {
    it('requests members of a group', async () => {
      const expectedUrl = `${mockUrlRoot}/api/${mockApiVersion}/groups/${mockGroupId}/members`;

      const response = [{ id: 0, username: 'root' }];

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

      await expect(getGroupMembers(mockGroupId)).resolves.toMatchObject({
        data: response,
      });
    });

    it('requests inherited members of a group when requested', async () => {
      const expectedUrl = `${mockUrlRoot}/api/${mockApiVersion}/groups/${mockGroupId}/members/all`;

      const response = [{ id: 0, username: 'root' }];

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

      await expect(getGroupMembers(mockGroupId, true)).resolves.toMatchObject({
        data: response,
      });
    });
  });
});
