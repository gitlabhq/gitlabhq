import MockAdapter from 'axios-mock-adapter';
import getGroupTransferLocationsResponse from 'test_fixtures/api/groups/transfer_locations.json';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_PER_PAGE } from '~/api';
import { updateGroup, getGroupTransferLocations } from '~/api/groups_api';

const mockApiVersion = 'v4';
const mockUrlRoot = '/gitlab';
const mockGroupId = '99';

describe('GroupsApi', () => {
  let originalGon;
  let mock;

  const dummyGon = {
    api_version: mockApiVersion,
    relative_url_root: mockUrlRoot,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
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

      mock.onGet(expectedUrl).replyOnce(200, { data: getGroupTransferLocationsResponse });

      await expect(getGroupTransferLocations(mockGroupId, params)).resolves.toMatchObject({
        data: { data: getGroupTransferLocationsResponse },
      });

      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { ...params, per_page: DEFAULT_PER_PAGE },
      });
    });
  });
});
