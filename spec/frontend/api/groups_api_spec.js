import MockAdapter from 'axios-mock-adapter';
import httpStatus from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import { updateGroup } from '~/api/groups_api';

const mockApiVersion = 'v4';
const mockUrlRoot = '/gitlab';

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
    const mockGroupId = '99';
    const mockData = { attr: 'value' };
    const expectedUrl = `${mockUrlRoot}/api/${mockApiVersion}/groups/${mockGroupId}`;

    beforeEach(() => {
      mock.onPut(expectedUrl).reply(({ data }) => {
        return [httpStatus.OK, { id: mockGroupId, ...JSON.parse(data) }];
      });
    });

    it('updates group', async () => {
      const res = await updateGroup(mockGroupId, mockData);

      expect(res.data).toMatchObject({ id: mockGroupId, ...mockData });
    });
  });
});
