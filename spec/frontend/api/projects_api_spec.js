import MockAdapter from 'axios-mock-adapter';
import getTransferLocationsResponse from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import project from 'test_fixtures/api/projects/put.json';
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

  describe('updateProject', () => {
    it('posts to the correct URL and returns the data', async () => {
      const data = { name: 'Foo bar', description: 'Mock description' };
      const expectedUrl = `/api/v7/projects/${projectId}`;

      mock.onPut(expectedUrl, data).replyOnce(HTTP_STATUS_OK, project);

      await expect(projectsApi.updateProject(projectId, data)).resolves.toMatchObject({
        data: project,
      });
    });
  });

  describe('deleteProject', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'delete');
    });

    describe('without params', () => {
      it('deletes to the correct URL', () => {
        const expectedUrl = `/api/v7/projects/${projectId}`;

        mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK);

        return projectsApi.deleteProject(projectId).then(() => {
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl, { params: undefined });
        });
      });
    });

    describe('with params', () => {
      it('deletes to the correct URL with params', () => {
        const expectedUrl = `/api/v7/projects/${projectId}`;

        mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK);

        return projectsApi.deleteProject(projectId, { testParam: true }).then(() => {
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl, { params: { testParam: true } });
        });
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

  describe('getProjectShareLocations', () => {
    it('requests share locations for a project', async () => {
      const expectedUrl = `/api/v7/projects/1/share_locations`;
      const params = { search: 'foo' };
      const axiosOptions = { mockOption: 'bar' };

      const response = [
        {
          id: 27,
          web_url: 'http://127.0.0.1:3000/groups/Commit451',
          name: 'Commit451',
          avatar_url: null,
          full_name: 'Commit451',
          full_path: 'Commit451',
        },
      ];

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

      await expect(
        projectsApi.getProjectShareLocations(projectId, params, axiosOptions),
      ).resolves.toMatchObject({
        data: response,
      });
      expect(mock.history.get[0].params).toEqual({ ...params, per_page: DEFAULT_PER_PAGE });
      expect(mock.history.get[0].mockOption).toBe(axiosOptions.mockOption);
    });
  });

  describe('uploadImageToProject', () => {
    const mockProjectId = 123;
    const mockFilename = 'test.jpg';
    const mockBlobData = new Blob(['test']);

    beforeEach(() => {
      window.gon = { relative_url_root: '', api_version: 'v7' };
      jest.spyOn(axios, 'post');
    });

    it('should upload an image and return the share URL', async () => {
      const mockResponse = {
        full_path: '/-/project/123/uploads/abcd/test.jpg',
      };

      mock.onPost().replyOnce(HTTP_STATUS_OK, mockResponse);

      const result = await projectsApi.uploadImageToProject({
        filename: mockFilename,
        blobData: mockBlobData,
        projectId: mockProjectId,
      });

      expect(axios.post).toHaveBeenCalledWith(
        `/api/v7/projects/${mockProjectId}/uploads`,
        expect.any(FormData),
        expect.objectContaining({
          headers: { 'Content-Type': 'multipart/form-data' },
        }),
      );
      expect(result).toBe('http://test.host/-/project/123/uploads/abcd/test.jpg');
    });

    it('should throw an error if filename is missing', async () => {
      await expect(
        projectsApi.uploadImageToProject({
          blobData: mockBlobData,
          projectId: mockProjectId,
        }),
      ).rejects.toThrow('Request failed with status code 404');
    });

    it('should throw an error if blobData is missing', async () => {
      await expect(
        projectsApi.uploadImageToProject({
          filename: mockFilename,
          projectId: mockProjectId,
        }),
      ).rejects.toThrow("is not of type 'Blob'");
    });

    it('should throw an error if projectId is missing', async () => {
      await expect(
        projectsApi.uploadImageToProject({
          filename: mockFilename,
          blobData: mockBlobData,
        }),
      ).rejects.toThrow('Request failed with status code 404');
    });

    it('should throw an error if the upload fails', async () => {
      mock.onPost().replyOnce(500);

      await expect(
        projectsApi.uploadImageToProject({
          filename: mockFilename,
          blobData: mockBlobData,
          projectId: mockProjectId,
        }),
      ).rejects.toThrow('Request failed with status code 500');
    });

    it('should throw an error if the response does not have a link', async () => {
      mock.onPost().replyOnce(HTTP_STATUS_OK, {});

      await expect(
        projectsApi.uploadImageToProject({
          filename: mockFilename,
          blobData: mockBlobData,
          projectId: mockProjectId,
        }),
      ).rejects.toThrow('Image failed to upload');
    });
  });
});
