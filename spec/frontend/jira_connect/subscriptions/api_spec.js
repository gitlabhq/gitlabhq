import MockAdapter from 'axios-mock-adapter';
import {
  axiosInstance,
  removeSubscription,
  fetchGroups,
  getCurrentUser,
  addJiraConnectSubscription,
  updateInstallation,
} from '~/jira_connect/subscriptions/api';
import { getJwt } from '~/jira_connect/subscriptions/utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  getJwt: jest.fn().mockResolvedValue('jwt'),
}));

describe('JiraConnect API', () => {
  let axiosMock;
  let response;

  const mockRemovePath = 'removePath';
  const mockNamespace = 'namespace';
  const mockJwt = 'jwt';
  const mockAccessToken = 'accessToken';
  const mockResponse = { success: true };

  beforeEach(() => {
    axiosMock = new MockAdapter(axiosInstance);
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    axiosMock.restore();
    response = null;
  });

  describe('removeSubscription', () => {
    const makeRequest = () => removeSubscription(mockRemovePath);

    it('returns success response', async () => {
      jest.spyOn(axiosInstance, 'delete');
      axiosMock.onDelete(mockRemovePath).replyOnce(HTTP_STATUS_OK, mockResponse);

      response = await makeRequest();

      expect(getJwt).toHaveBeenCalled();
      expect(axiosInstance.delete).toHaveBeenCalledWith(mockRemovePath, {
        params: {
          jwt: mockJwt,
        },
      });
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('fetchGroups', () => {
    const mockGroupsPath = 'groupsPath';
    const mockMinAccessLevel = 30;
    const mockPage = 1;
    const mockPerPage = 10;

    const makeRequest = () =>
      fetchGroups(mockGroupsPath, {
        minAccessLevel: mockMinAccessLevel,
        page: mockPage,
        perPage: mockPerPage,
      });

    it('returns success response', async () => {
      jest.spyOn(axiosInstance, 'get');
      axiosMock
        .onGet(mockGroupsPath, {
          min_access_level: mockMinAccessLevel,
          page: mockPage,
          per_page: mockPerPage,
        })
        .replyOnce(HTTP_STATUS_OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.get).toHaveBeenCalledWith(mockGroupsPath, {
        headers: {},
        params: {
          min_access_level: mockMinAccessLevel,
          page: mockPage,
          per_page: mockPerPage,
          search: undefined,
        },
      });
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('getCurrentUser', () => {
    const makeRequest = () => getCurrentUser();

    it('returns success response', async () => {
      const expectedUrl = '/api/v4/user';

      jest.spyOn(axiosInstance, 'get');

      axiosMock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.get).toHaveBeenCalledWith(expectedUrl, {});
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('addJiraConnectSubscription', () => {
    const makeRequest = () =>
      addJiraConnectSubscription(mockNamespace, { jwt: mockJwt, accessToken: mockAccessToken });

    it('returns success response', async () => {
      const expectedUrl = '/api/v4/integrations/jira_connect/subscriptions';

      jest.spyOn(axiosInstance, 'post');

      axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.post).toHaveBeenCalledWith(
        expectedUrl,
        {
          jwt: mockJwt,
          namespace_path: mockNamespace,
        },
        { headers: { Authorization: `Bearer ${mockAccessToken}` } },
      );
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('updateInstallation', () => {
    const expectedUrl = '/-/jira_connect/installations';

    it.each`
      instanceUrl                       | expectedInstanceUrl
      ${'https://gitlab.com'}           | ${null}
      ${'https://gitlab.mycompany.com'} | ${'https://gitlab.mycompany.com'}
    `(
      'when instanceUrl is $instanceUrl, it passes `instance_url` as $expectedInstanceUrl',
      async ({ instanceUrl, expectedInstanceUrl }) => {
        const makeRequest = () => updateInstallation(instanceUrl);

        jest.spyOn(axiosInstance, 'put');
        axiosMock
          .onPut(expectedUrl, {
            jwt: mockJwt,
            installation: {
              instance_url: expectedInstanceUrl,
            },
          })
          .replyOnce(HTTP_STATUS_OK, mockResponse);

        response = await makeRequest();

        expect(getJwt).toHaveBeenCalled();
        expect(axiosInstance.put).toHaveBeenCalledWith(expectedUrl, {
          jwt: mockJwt,
          installation: {
            instance_url: expectedInstanceUrl,
          },
        });
        expect(response.data).toEqual(mockResponse);
      },
    );
  });
});
