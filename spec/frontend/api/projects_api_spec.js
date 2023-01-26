import MockAdapter from 'axios-mock-adapter';
import getTransferLocationsResponse from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import * as projectsApi from '~/api/projects_api';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/projects_api.js', () => {
  let mock;
  let originalGon;

  const projectId = 1;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    originalGon = window.gon;
    window.gon = { api_version: 'v7' };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('getProjects', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    it('retrieves projects from the correct URL and returns them in the response data', () => {
      const expectedUrl = '/api/v7/projects.json';
      const expectedParams = { params: { per_page: 20, search: '', simple: true } };
      const expectedProjects = [{ name: 'project 1' }];
      const query = '';
      const options = {};

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedProjects });

      return projectsApi.getProjects(query, options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, expectedParams);
        expect(data.data).toEqual(expectedProjects);
      });
    });
  });

  describe('importProjectMembers', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'post');
    });

    it('posts to the correct URL and returns the response message', () => {
      const targetId = 2;
      const expectedUrl = '/api/v7/projects/1/import_project_members/2';
      const expectedMessage = 'Successfully imported';

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedMessage);

      return projectsApi.importProjectMembers(projectId, targetId).then(({ data }) => {
        expect(axios.post).toHaveBeenCalledWith(expectedUrl);
        expect(data).toEqual(expectedMessage);
      });
    });
  });

  describe('getTransferLocations', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    it('retrieves transfer locations from the correct URL and returns them in the response data', async () => {
      const params = { page: 1 };
      const expectedUrl = '/api/v7/projects/1/transfer_locations';

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, { data: getTransferLocationsResponse });

      await expect(projectsApi.getTransferLocations(projectId, params)).resolves.toMatchObject({
        data: { data: getTransferLocationsResponse },
      });

      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { ...params, per_page: DEFAULT_PER_PAGE },
      });
    });
  });
});
