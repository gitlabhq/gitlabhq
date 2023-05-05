import MockAdapter from 'axios-mock-adapter';
import getTransferLocationsResponse from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import * as projectsApi from '~/api/projects_api';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/projects_api.js', () => {
  let mock;

  const projectId = 1;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    window.gon = { api_version: 'v7' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getProjects', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    const expectedUrl = '/api/v7/projects.json';
    const expectedProjects = [{ name: 'project 1' }];
    const options = {};

    it('retrieves projects from the correct URL and returns them in the response data', () => {
      const expectedParams = { params: { per_page: 20, search: '', simple: true } };
      const query = '';

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedProjects });

      return projectsApi.getProjects(query, options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, expectedParams);
        expect(data.data).toEqual(expectedProjects);
      });
    });

    it('omits search param if query is undefined', () => {
      const expectedParams = { params: { per_page: 20, simple: true } };

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedProjects });

      return projectsApi.getProjects(undefined, options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, expectedParams);
        expect(data.data).toEqual(expectedProjects);
      });
    });

    it('searches namespaces if query contains a slash', () => {
      const expectedParams = {
        params: { per_page: 20, search: 'group/project1', search_namespaces: true, simple: true },
      };
      const query = 'group/project1';

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedProjects });

      return projectsApi.getProjects(query, options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, expectedParams);
        expect(data.data).toEqual(expectedProjects);
      });
    });
  });

  describe('createProject', () => {
    it('posts to the correct URL and returns the data', () => {
      const body = { name: 'test project' };
      const expectedUrl = '/api/v7/projects.json';
      const expectedRes = { id: 999, name: 'test project' };

      mock.onPost(expectedUrl, body).replyOnce(HTTP_STATUS_OK, { data: expectedRes });

      return projectsApi.createProject(body).then(({ data }) => {
        expect(data).toStrictEqual(expectedRes);
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

  describe('getProjectMembers', () => {
    it('requests members of a project', async () => {
      const expectedUrl = `/api/v7/projects/1/members`;

      const response = [{ id: 0, username: 'root' }];

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

      await expect(projectsApi.getProjectMembers(projectId)).resolves.toMatchObject({
        data: response,
      });
    });

    it('requests inherited members of a project when requested', async () => {
      const expectedUrl = `/api/v7/projects/1/members/all`;

      const response = [{ id: 0, username: 'root' }];

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

      await expect(projectsApi.getProjectMembers(projectId, true)).resolves.toMatchObject({
        data: response,
      });
    });
  });
});
