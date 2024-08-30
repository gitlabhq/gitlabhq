import MockAdapter from 'axios-mock-adapter';
import Api from '~/api';
import { getProjects } from '~/rest_api';
import { ACCESS_LEVEL_REPORTER_INTEGER } from '~/access_level/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import axios from '~/lib/utils/axios_utils';
import {
  fetchProjectGroups,
  fetchAllGroups,
  fetchGroupsWithProjectAccess,
  fetchProjects,
  fetchUsers,
} from '~/vue_shared/components/list_selector/api';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/api');
jest.mock('~/rest_api');
jest.mock('~/graphql_shared/utils');
let axiosMock;

const mockProjectPath = 'group/project';
const mockGroupSearch = 'group';

describe('List Selector Utils', () => {
  describe('fetchProjectGroups', () => {
    const mockApiResponse = [
      { id: 1, full_name: 'Group 1', name: 'group1' },
      { id: 2, full_name: 'Group 2', name: 'group2' },
    ];

    beforeEach(() => {
      Api.projectGroups.mockResolvedValue(mockApiResponse);
    });

    it('calls Api.projectGroups with correct parameters', async () => {
      await fetchProjectGroups(mockProjectPath, mockGroupSearch);

      expect(Api.projectGroups).toHaveBeenCalledWith(mockProjectPath, {
        search: mockGroupSearch,
        with_shared: true,
        shared_min_access_level: ACCESS_LEVEL_REPORTER_INTEGER,
      });
    });

    it('returns formatted group data', async () => {
      const result = await fetchProjectGroups(mockProjectPath, mockGroupSearch);

      expect(result).toEqual([
        { text: 'Group 1', value: 'group1', id: 1, fullName: 'Group 1', name: 'group1' },
        { text: 'Group 2', value: 'group2', id: 2, fullName: 'Group 2', name: 'group2' },
      ]);
    });
  });

  describe('fetchAllGroups', () => {
    const mockApollo = {
      query: jest.fn(),
    };
    const mockGraphQLResponse = {
      data: {
        groups: {
          nodes: [
            { id: 'gid://gitlab/Group/1', fullName: 'Group 1', name: 'group1' },
            { id: 'gid://gitlab/Group/2', fullName: 'Group 2', name: 'group2' },
          ],
        },
      },
    };

    beforeEach(() => {
      mockApollo.query.mockResolvedValue(mockGraphQLResponse);
      getIdFromGraphQLId.mockImplementation((id) => parseInt(id.split('/').pop(), 10));
    });

    it('calls apollo.query with correct parameters', async () => {
      await fetchAllGroups(mockApollo, mockGroupSearch);

      expect(mockApollo.query).toHaveBeenCalledWith({
        query: expect.any(Object),
        variables: { search: mockGroupSearch },
      });
    });

    it('returns formatted group data', async () => {
      const result = await fetchAllGroups(mockApollo, mockGroupSearch);

      expect(result).toEqual([
        {
          text: 'Group 1',
          value: 'group1',
          id: 1,
          fullName: 'Group 1',
          name: 'group1',
          type: 'group',
        },
        {
          text: 'Group 2',
          value: 'group2',
          id: 2,
          fullName: 'Group 2',
          name: 'group2',
          type: 'group',
        },
      ]);
    });
  });

  describe('fetchGroupsWithProjectAccess', () => {
    const mockProjectId = 7;
    const mockUrl = '/-/autocomplete/project_groups.json';

    beforeEach(() => {
      const mockAxiosResponse = [
        { id: 1, avatar_url: null, name: 'group1' },
        { id: 2, avatar_url: null, name: 'group2' },
      ];
      axiosMock = new MockAdapter(axios);
      axiosMock.onGet(mockUrl).replyOnce(HTTP_STATUS_OK, mockAxiosResponse);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('calls axios.get with correct parameters', async () => {
      await fetchGroupsWithProjectAccess(mockProjectId, mockGroupSearch);

      expect(axiosMock.history.get.length).toBe(1);
      expect(axiosMock.history.get[0].params).toStrictEqual({
        project_id: mockProjectId,
        with_project_access: true,
        search: mockGroupSearch,
      });
    });

    it('returns formatted group data', async () => {
      const result = await fetchGroupsWithProjectAccess(mockProjectId, mockGroupSearch);

      expect(result).toEqual([
        { text: 'group1', value: 'group1', id: 1, avatarUrl: null, name: 'group1' },
        { text: 'group2', value: 'group2', id: 2, avatarUrl: null, name: 'group2' },
      ]);
    });
  });

  describe('fetchProjects', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('calls getProjects with correct parameters', async () => {
      const search = 'test';
      await fetchProjects(search);
      expect(getProjects).toHaveBeenCalledWith(search, { membership: false });
    });

    it('returns formatted project data', async () => {
      const mockProjects = [
        { name: 'Project 1', id: 1 },
        { name: 'Project 2', id: 2 },
      ];
      getProjects.mockResolvedValue({ data: mockProjects });

      const result = await fetchProjects('project');

      expect(result).toEqual([
        { id: 1, name: 'Project 1', text: 'Project 1', value: 1, type: 'project' },
        { id: 2, name: 'Project 2', text: 'Project 2', value: 2, type: 'project' },
      ]);
    });
  });

  describe('fetchUsers', () => {
    const mockSearch = 'john';
    const mockUsersQueryOptions = { push_code: true, active: true };

    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('calls Api.projectUsers with correct parameters', async () => {
      await fetchUsers(mockProjectPath, mockSearch, mockUsersQueryOptions);
      expect(Api.projectUsers).toHaveBeenCalledWith(
        mockProjectPath,
        mockSearch,
        mockUsersQueryOptions,
      );
    });

    it('returns mapped user objects when Api.projectUsers returns data', async () => {
      const mockUsers = [
        { id: 1, name: 'John Doe', username: 'john_doe' },
        { id: 2, name: 'Jane Smith', username: 'jane_smith' },
      ];
      Api.projectUsers.mockResolvedValue(mockUsers);

      const result = await fetchUsers(mockProjectPath, mockSearch, mockUsersQueryOptions);

      expect(result).toEqual([
        { id: 1, name: 'John Doe', username: 'john_doe', text: 'John Doe', value: 'john_doe' },
        {
          id: 2,
          name: 'Jane Smith',
          username: 'jane_smith',
          text: 'Jane Smith',
          value: 'jane_smith',
        },
      ]);
    });
  });
});
