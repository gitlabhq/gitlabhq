import MockAdapter from 'axios-mock-adapter';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';

  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = {
      api_version: dummyApiVersion,
      relative_url_root: dummyUrlRoot,
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('buildUrl', () => {
    it('adds URL root and fills in API version', () => {
      const input = '/api/:version/foo/bar';
      const expectedOutput = `${dummyUrlRoot}/api/${dummyApiVersion}/foo/bar`;

      const builtUrl = Api.buildUrl(input);

      expect(builtUrl).toEqual(expectedOutput);
    });

    [null, '', '/'].forEach((root) => {
      it(`works when relative_url_root is ${root}`, () => {
        window.gon.relative_url_root = root;
        const input = '/api/:version/foo/bar';
        const expectedOutput = `/api/${dummyApiVersion}/foo/bar`;

        const builtUrl = Api.buildUrl(input);

        expect(builtUrl).toEqual(expectedOutput);
      });
    });
  });

  describe('projectGroups', () => {
    const projectId = '123';
    const options = { search: 'foo' };
    const apiResponse = [{ id: 1, name: 'foo' }];

    it('fetch all project groups', () => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/groups.json`;
      jest.spyOn(axios, 'get');
      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

      return Api.projectGroups(projectId, options).then((data) => {
        expect(data).toEqual(apiResponse);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { ...options } });
      });
    });
  });

  describe('packages', () => {
    const projectId = 'project_a';
    const packageId = 'package_b';
    const apiResponse = [{ id: 1, name: 'foo' }];

    describe('groupPackages', () => {
      const groupId = 'group_a';

      it('fetch all group packages', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/packages`;
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return Api.groupPackages(groupId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
        });
      });
    });

    describe('projectPackages', () => {
      it('fetch all project packages', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/packages`;
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return Api.projectPackages(projectId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
        });
      });
    });

    describe('buildProjectPackageUrl', () => {
      it('returns the right url', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/packages/${packageId}`;
        const url = Api.buildProjectPackageUrl(projectId, packageId);
        expect(url).toEqual(expectedUrl);
      });
    });

    describe('projectPackage', () => {
      it('fetch package details', () => {
        const expectedUrl = `foo`;
        jest.spyOn(Api, 'buildProjectPackageUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return Api.projectPackage(projectId, packageId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });

    describe('deleteProjectPackage', () => {
      it('delete a package', () => {
        const expectedUrl = `foo`;

        jest.spyOn(Api, 'buildProjectPackageUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'delete');
        mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK, true);

        return Api.deleteProjectPackage(projectId, packageId).then(({ data }) => {
          expect(data).toEqual(true);
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });

    describe('deleteProjectPackageFile', () => {
      const packageFileId = 'package_file_id';

      it('delete a package', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/packages/${packageId}/package_files/${packageFileId}`;

        jest.spyOn(axios, 'delete');
        mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK, true);

        return Api.deleteProjectPackageFile(projectId, packageId, packageFileId).then(
          ({ data }) => {
            expect(data).toEqual(true);
            expect(axios.delete).toHaveBeenCalledWith(expectedUrl);
          },
        );
      });
    });
  });

  describe('container registry', () => {
    describe('containerRegistryDetails', () => {
      it('fetch container registry  details', async () => {
        const expectedUrl = `foo`;
        const apiResponse = {};

        jest.spyOn(axios, 'get');
        jest.spyOn(Api, 'buildUrl').mockReturnValueOnce(expectedUrl);
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        const { data } = await Api.containerRegistryDetails(1);

        expect(data).toEqual(apiResponse);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
      });
    });
  });

  describe('group', () => {
    it('fetches a group', () => {
      const groupId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        name: 'test',
      });

      return new Promise((resolve) => {
        Api.group(groupId, (response) => {
          expect(response.name).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('groupMembers', () => {
    it('fetches group members', () => {
      const groupId = '54321';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/members`;
      const expectedData = [{ id: 7 }];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectedData);

      return Api.groupMembers(groupId).then(({ data }) => {
        expect(data).toEqual(expectedData);
      });
    });
  });

  describe('groupSubgroups', () => {
    it('fetches group subgroups', () => {
      const groupId = '54321';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/subgroups`;
      const expectedData = [{ id: 7 }];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectedData);

      return Api.groupSubgroups(groupId).then(({ data }) => {
        expect(data).toEqual(expectedData);
      });
    });
  });

  describe('inviteGroupMembers', () => {
    it('invites a new email address to create a new User and become a Group Member', () => {
      const groupId = 1;
      const email = 'email@example.com';
      const userId = '1';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/1/invitations`;
      const params = {
        email,
        userId,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, {
        status: 'success',
      });

      return Api.inviteGroupMembers(groupId, params).then(({ data }) => {
        expect(data.status).toBe('success');
      });
    });
  });

  describe('groupMilestones', () => {
    it('fetches group milestones', () => {
      const groupId = '16';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/milestones`;
      const expectedData = [
        {
          id: 12,
          iid: 3,
          group_id: 16,
          title: '10.0',
          description: 'Version',
          due_date: '2013-11-29',
          start_date: '2013-11-10',
          state: 'active',
          updated_at: '2013-10-02T09:24:18Z',
          created_at: '2013-10-02T09:24:18Z',
          web_url: 'https://gitlab.com/groups/gitlab-org/-/milestones/42',
        },
      ];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectedData);

      return Api.groupMilestones(groupId).then(({ data }) => {
        expect(data).toEqual(expectedData);
      });
    });
  });

  describe('groups', () => {
    it('fetches groups', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups.json`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return new Promise((resolve) => {
        Api.groups(query, options, (response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('groupLabels', () => {
    it('fetches group labels', () => {
      const options = { params: { search: 'foo' } };
      const expectedGroup = 'gitlab-org';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${expectedGroup}/labels`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          id: 1,
          name: 'Foo Label',
        },
      ]);

      return Api.groupLabels(expectedGroup, options).then((res) => {
        expect(res.length).toBe(1);
        expect(res[0].name).toBe('Foo Label');
      });
    });
  });

  describe('namespaces', () => {
    it('fetches namespaces', () => {
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/namespaces.json`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return new Promise((resolve) => {
        Api.namespaces(query, (response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('projects', () => {
    it('fetches projects with membership when logged in', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      window.gon.current_user_id = 1;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return new Promise((resolve) => {
        Api.projects(query, options, (response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
          resolve();
        });
      });
    });

    it('fetches projects without membership when not logged in', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return new Promise((resolve) => {
        Api.projects(query, options, (response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('updateProject', () => {
    it('update a project with the given payload', () => {
      const projectPath = 'foo';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}`;
      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, { foo: 'bar' });

      return Api.updateProject(projectPath, { foo: 'bar' }).then(({ data }) => {
        expect(data.foo).toBe('bar');
      });
    });
  });

  describe('projectUsers', () => {
    it('fetches all users of a particular project', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const projectPath = 'gitlab-org%2Fgitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/users`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return Api.projectUsers('gitlab-org/gitlab-ce', query, options).then((response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
      });
    });
  });

  describe('projectMergeRequests', () => {
    const projectPath = 'abc';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests`;

    it('fetches all merge requests for a project', () => {
      const mockData = [{ source_branch: 'foo' }, { source_branch: 'bar' }];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, mockData);
      return Api.projectMergeRequests(projectPath).then(({ data }) => {
        expect(data.length).toEqual(2);
        expect(data[0].source_branch).toBe('foo');
        expect(data[1].source_branch).toBe('bar');
      });
    });

    it('fetches merge requests filtered with passed params', () => {
      const params = {
        source_branch: 'bar',
      };
      const mockData = [{ source_branch: 'bar' }];
      mock.onGet(expectedUrl, { params }).reply(HTTP_STATUS_OK, mockData);

      return Api.projectMergeRequests(projectPath, params).then(({ data }) => {
        expect(data.length).toEqual(1);
        expect(data[0].source_branch).toBe('bar');
      });
    });
  });

  describe('projectMergeRequest', () => {
    it('fetches a merge request', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        title: 'test',
      });

      return Api.projectMergeRequest(projectPath, mergeRequestId).then(({ data }) => {
        expect(data.title).toBe('test');
      });
    });
  });

  describe('projectMergeRequestChanges', () => {
    it('fetches the changes of a merge request', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/changes`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        title: 'test',
      });

      return Api.projectMergeRequestChanges(projectPath, mergeRequestId).then(({ data }) => {
        expect(data.title).toBe('test');
      });
    });
  });

  describe('projectMergeRequestVersions', () => {
    it('fetches the versions of a merge request', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/versions`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          id: 123,
        },
      ]);

      return Api.projectMergeRequestVersions(projectPath, mergeRequestId).then(({ data }) => {
        expect(data.length).toBe(1);
        expect(data[0].id).toBe(123);
      });
    });
  });

  describe('projectRunners', () => {
    it('fetches the runners of a project', () => {
      const projectPath = 7;
      const params = { scope: 'active' };
      const mockData = [{ id: 4 }];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/runners`;
      mock.onGet(expectedUrl, { params }).reply(HTTP_STATUS_OK, mockData);

      return Api.projectRunners(projectPath, { params }).then(({ data }) => {
        expect(data).toEqual(mockData);
      });
    });
  });

  describe('projectShareWithGroup', () => {
    it('invites a group to share access with the authenticated project', () => {
      const projectId = 1;
      const sharedGroupId = 99;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/share`;
      const options = {
        group_id: sharedGroupId,
        group_access: 10,
        expires_at: undefined,
        member_role_id: 88,
      };

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, {
        status: 'success',
      });

      return Api.projectShareWithGroup(projectId, options).then(({ data }) => {
        expect(data.status).toBe('success');
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, options);
      });
    });
  });

  describe('projectMilestones', () => {
    it('fetches project milestones', () => {
      const projectId = 1;
      const options = { state: 'active' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/milestones`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          id: 1,
          title: 'milestone1',
          state: 'active',
        },
      ]);

      return Api.projectMilestones(projectId, options).then(({ data }) => {
        expect(data.length).toBe(1);
        expect(data[0].title).toBe('milestone1');
      });
    });
  });

  describe('addProjectIssueAsTodo', () => {
    it('adds issue ID as a todo', () => {
      const projectId = 1;
      const issueIid = 11;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/issues/11/todo`;
      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, {
        id: 112,
        project: {
          id: 1,
        },
      });

      return Api.addProjectIssueAsTodo(projectId, issueIid).then(({ data }) => {
        expect(data.id).toBe(112);
        expect(data.project.id).toBe(projectId);
      });
    });
  });

  describe('inviteProjectMembers', () => {
    it('invites a new email address to create a new User and become a Project Member', () => {
      const projectId = 1;
      const email = 'email@example.com';
      const userId = '1';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/invitations`;
      const params = {
        email,
        userId,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, {
        status: 'success',
      });

      return Api.inviteProjectMembers(projectId, params).then(({ data }) => {
        expect(data.status).toBe('success');
      });
    });
  });

  describe('newLabel', () => {
    it('creates a new project label', () => {
      const namespace = 'some namespace';
      const project = 'some project';
      const labelData = { some: 'data' };
      const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/-/labels`;
      const expectedData = {
        label: labelData,
      };
      mock.onPost(expectedUrl).reply((config) => {
        expect(config.data).toBe(JSON.stringify(expectedData));

        return [
          HTTP_STATUS_OK,
          {
            name: 'test',
          },
        ];
      });

      return new Promise((resolve) => {
        Api.newLabel(namespace, project, labelData, (response) => {
          expect(response.name).toBe('test');
          resolve();
        });
      });
    });

    it('creates a new group label', () => {
      const namespace = 'group/subgroup';
      const labelData = { name: 'Foo', color: '#000000' };
      const expectedUrl = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespace);
      mock.onPost(expectedUrl).reply((config) => {
        expect(config.data).toBe(JSON.stringify({ color: labelData.color }));

        return [
          HTTP_STATUS_OK,
          {
            ...labelData,
          },
        ];
      });

      return new Promise((resolve) => {
        Api.newLabel(namespace, undefined, labelData, (response) => {
          expect(response.name).toBe('Foo');
          resolve();
        });
      });
    });
  });

  describe('groupProjects', () => {
    it('fetches group projects', () => {
      const groupId = '123456';
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/projects.json`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return Api.groupProjects(groupId, query, {}).then((response) => {
        expect(response.data.length).toBe(1);
        expect(response.data[0].name).toBe('test');
      });
    });

    it('NOT uses flesh on error with param useCustomErrorHandler', async () => {
      const groupId = '123456';
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/projects.json`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, null);
      const apiCall = Api.groupProjects(groupId, query, {});
      await expect(apiCall).rejects.toThrow();
    });
  });

  describe('groupShareWithGroup', () => {
    it('invites a group to share access with the authenticated group', () => {
      const groupId = 1;
      const sharedGroupId = 99;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/share`;
      const options = {
        group_id: sharedGroupId,
        group_access: 10,
        expires_at: undefined,
      };

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, {
        status: 'success',
      });

      return Api.groupShareWithGroup(groupId, options).then(({ data }) => {
        expect(data.status).toBe('success');
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, options);
      });
    });
  });

  describe('commit', () => {
    const projectId = 'user/project';
    const sha = 'abcd0123';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
      projectId,
    )}/repository/commits/${sha}`;

    it('fetches a single commit', () => {
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { id: sha });

      return Api.commit(projectId, sha).then(({ data: commit }) => {
        expect(commit.id).toBe(sha);
      });
    });

    it('fetches a single commit without stats', () => {
      mock.onGet(expectedUrl, { params: { stats: false } }).reply(HTTP_STATUS_OK, { id: sha });

      return Api.commit(projectId, sha, { stats: false }).then(({ data: commit }) => {
        expect(commit.id).toBe(sha);
      });
    });
  });

  describe('issueTemplate', () => {
    const namespace = 'some namespace';
    const project = 'some project';
    const templateKey = ' template #%?.key ';
    const templateType = 'template type';
    const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/templates/${templateType}/${encodeURIComponent(
      templateKey,
    )}`;

    it('fetches an issue template', () => {
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, 'test');

      return new Promise((resolve) => {
        Api.issueTemplate(namespace, project, templateKey, templateType, (_, response) => {
          expect(response).toBe('test');
          resolve();
        });
      });
    });

    describe('when an error occurs while fetching an issue template', () => {
      it('rejects the Promise', () => {
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        return new Promise((resolve) => {
          Api.issueTemplate(namespace, project, templateKey, templateType, () => {
            expect(mock.history.get).toHaveLength(1);
            resolve();
          });
        });
      });
    });
  });

  describe('issueTemplates', () => {
    const namespace = 'some namespace';
    const project = 'some project';
    const templateType = 'template type';
    const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/templates/${templateType}`;

    it('fetches all templates by type', () => {
      const expectedData = [
        { key: 'Template1', name: 'Template 1', content: 'This is template 1!' },
      ];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectedData);

      return new Promise((resolve) => {
        Api.issueTemplates(namespace, project, templateType, (_, response) => {
          expect(response.length).toBe(1);
          const { key, name, content } = response[0];
          expect(key).toBe('Template1');
          expect(name).toBe('Template 1');
          expect(content).toBe('This is template 1!');
          resolve();
        });
      });
    });

    describe('when an error occurs while fetching issue templates', () => {
      it('rejects the Promise', () => {
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        Api.issueTemplates(namespace, project, templateType, () => {
          expect(mock.history.get).toHaveLength(1);
        });
      });
    });
  });

  describe('projectTemplates', () => {
    it('fetches a list of templates', () => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, 'test');

      return new Promise((resolve) => {
        Api.projectTemplates('gitlab-org/gitlab-ce', 'licenses', {}, (response) => {
          expect(response).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('projectTemplate', () => {
    it('fetches a single template', () => {
      const data = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses/test%20license`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, 'test');

      return new Promise((resolve) => {
        Api.projectTemplate(
          'gitlab-org/gitlab-ce',
          'licenses',
          'test license',
          data,
          (response) => {
            expect(response).toBe('test');
            resolve();
          },
        );
      });
    });
  });

  describe('users', () => {
    it('fetches users', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users.json`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return Api.users(query, options).then(({ data }) => {
        expect(data.length).toBe(1);
        expect(data[0].name).toBe('test');
      });
    });
  });

  describe('user', () => {
    it('fetches single user', () => {
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        name: 'testuser',
      });

      return Api.user(userId).then(({ data }) => {
        expect(data.name).toBe('testuser');
      });
    });
  });

  describe('user counts', () => {
    it('fetches single user counts', () => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/user_counts`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        merge_requests: 4,
      });

      return Api.userCounts().then(({ data }) => {
        expect(data.merge_requests).toBe(4);
      });
    });
  });

  describe('user status', () => {
    it('fetches single user status', () => {
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}/status`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        message: 'testmessage',
      });

      return Api.userStatus(userId).then(({ data }) => {
        expect(data.message).toBe('testmessage');
      });
    });
  });

  describe('user projects', () => {
    it('fetches all projects that belong to a particular user', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}/projects`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return new Promise((resolve) => {
        Api.userProjects(userId, query, options, (response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
          resolve();
        });
      });
    });
  });

  describe('commitPipelines', () => {
    it('fetches pipelines for a given commit', () => {
      const projectId = 'example/foobar';
      const commitSha = 'abc123def';
      const expectedUrl = `${dummyUrlRoot}/${projectId}/commit/${commitSha}/pipelines`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return Api.commitPipelines(projectId, commitSha).then(({ data }) => {
        expect(data.length).toBe(1);
        expect(data[0].name).toBe('test');
      });
    });
  });

  describe('createBranch', () => {
    it('creates new branch', () => {
      const ref = 'main';
      const branch = 'new-branch-name';
      const dummyProjectPath = 'gitlab-org/gitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
        dummyProjectPath,
      )}/repository/branches`;

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, {
        name: branch,
      });

      return Api.createBranch(dummyProjectPath, { ref, branch }).then(({ data }) => {
        expect(data.name).toBe(branch);
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, { ref, branch });
      });
    });
  });

  describe('postMergeRequestPipeline', () => {
    const dummyProjectId = 5;
    const dummyMergeRequestIid = 123;
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/5/merge_requests/123/pipelines`;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('creates a merge request pipeline async', () => {
      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, {
        id: 456,
      });

      return Api.postMergeRequestPipeline(dummyProjectId, {
        mergeRequestId: dummyMergeRequestIid,
      }).then(({ data }) => {
        expect(data.id).toBe(456);
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, { async: true });
      });
    });
  });

  describe('projectForks', () => {
    it('gets forked projects', () => {
      const dummyProjectPath = 'gitlab-org/gitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
        dummyProjectPath,
      )}/forks`;

      jest.spyOn(axios, 'get');

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, ['fork']);

      return Api.projectForks(dummyProjectPath, { visibility: 'private' }).then(({ data }) => {
        expect(data).toEqual(['fork']);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
          params: { visibility: 'private' },
        });
      });
    });
  });

  describe('createContextCommits', () => {
    it('creates a new context commit', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const commitsData = ['abcdefg'];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;
      const expectedData = {
        commits: commitsData,
      };

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, [
        {
          id: 'abcdefghijklmnop',
          short_id: 'abcdefg',
          title: 'Dummy commit',
        },
      ]);

      return Api.createContextCommits(projectPath, mergeRequestId, expectedData).then(
        ({ data }) => {
          expect(data[0].title).toBe('Dummy commit');
        },
      );
    });
  });

  describe('allContextCommits', () => {
    it('gets all context commits', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;

      jest.spyOn(axios, 'get');

      mock
        .onGet(expectedUrl)
        .replyOnce(HTTP_STATUS_OK, [
          { id: 'abcdef', short_id: 'abcdefghi', title: 'Dummy commit title' },
        ]);

      return Api.allContextCommits(projectPath, mergeRequestId).then(({ data }) => {
        expect(data[0].title).toBe('Dummy commit title');
      });
    });
  });

  describe('removeContextCommits', () => {
    it('removes context commits', () => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const commitsData = ['abcdefg'];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;
      const expectedData = {
        commits: commitsData,
      };

      jest.spyOn(axios, 'delete');

      mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_NO_CONTENT);

      return Api.removeContextCommits(projectPath, mergeRequestId, expectedData).then(() => {
        expect(axios.delete).toHaveBeenCalledWith(expectedUrl, { data: expectedData });
      });
    });
  });

  describe('release-related methods', () => {
    const dummyProjectPath = 'gitlab-org/gitlab';
    const dummyTagName = 'v1.3';
    const baseReleaseUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
      dummyProjectPath,
    )}/releases`;

    describe('releases', () => {
      const expectedUrl = baseReleaseUrl;

      describe('when releases are successfully returned', () => {
        it('resolves the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK);

          return Api.releases(dummyProjectPath).then(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while fetching releases', () => {
        it('rejects the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.releases(dummyProjectPath).catch(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });
    });

    describe('release', () => {
      const expectedUrl = `${baseReleaseUrl}/${encodeURIComponent(dummyTagName)}`;

      describe('when the release is successfully returned', () => {
        it('resolves the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK);

          return Api.release(dummyProjectPath, dummyTagName).then(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while fetching the release', () => {
        it('rejects the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.release(dummyProjectPath, dummyTagName).catch(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });
    });

    describe('createRelease', () => {
      const expectedUrl = baseReleaseUrl;

      const release = {
        name: 'Version 1.0',
      };

      describe('when the release is successfully created', () => {
        it('resolves the Promise', () => {
          mock.onPost(expectedUrl, release).replyOnce(HTTP_STATUS_CREATED);

          return Api.createRelease(dummyProjectPath, release).then(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while creating the release', () => {
        it('rejects the Promise', () => {
          mock.onPost(expectedUrl, release).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.createRelease(dummyProjectPath, release).catch(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });
    });

    describe('updateRelease', () => {
      const expectedUrl = `${baseReleaseUrl}/${encodeURIComponent(dummyTagName)}`;

      const release = {
        name: 'Version 1.0',
      };

      describe('when the release is successfully updated', () => {
        it('resolves the Promise', () => {
          mock.onPut(expectedUrl, release).replyOnce(HTTP_STATUS_OK);

          return Api.updateRelease(dummyProjectPath, dummyTagName, release).then(() => {
            expect(mock.history.put).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while updating the release', () => {
        it('rejects the Promise', () => {
          mock.onPut(expectedUrl, release).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.updateRelease(dummyProjectPath, dummyTagName, release).catch(() => {
            expect(mock.history.put).toHaveLength(1);
          });
        });
      });
    });

    describe('createReleaseLink', () => {
      const expectedUrl = `${baseReleaseUrl}/${dummyTagName}/assets/links`;
      const expectedLink = {
        url: 'https://example.com',
        name: 'An example link',
      };

      describe('when the Release is successfully created', () => {
        it('resolves the Promise', () => {
          mock.onPost(expectedUrl, expectedLink).replyOnce(HTTP_STATUS_CREATED);

          return Api.createReleaseLink(dummyProjectPath, dummyTagName, expectedLink).then(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while creating the Release', () => {
        it('rejects the Promise', () => {
          mock.onPost(expectedUrl, expectedLink).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.createReleaseLink(dummyProjectPath, dummyTagName, expectedLink).catch(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });
    });

    describe('deleteReleaseLink', () => {
      const dummyLinkId = '4';
      const expectedUrl = `${baseReleaseUrl}/${dummyTagName}/assets/links/${dummyLinkId}`;

      describe('when the Release is successfully deleted', () => {
        it('resolves the Promise', () => {
          mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK);

          return Api.deleteReleaseLink(dummyProjectPath, dummyTagName, dummyLinkId).then(() => {
            expect(mock.history.delete).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while deleting the Release', () => {
        it('rejects the Promise', () => {
          mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          return Api.deleteReleaseLink(dummyProjectPath, dummyTagName, dummyLinkId).catch(() => {
            expect(mock.history.delete).toHaveLength(1);
          });
        });
      });
    });
  });

  describe('getRawFile', () => {
    const dummyProjectPath = 'gitlab-org/gitlab';
    const dummyFilePath = 'doc/CONTRIBUTING.md';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
      dummyProjectPath,
    )}/repository/files/${encodeURIComponent(dummyFilePath)}/raw`;

    describe('when the raw file is successfully fetched', () => {
      beforeEach(() => {
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK);
      });

      it('resolves the Promise', () => {
        return Api.getRawFile(dummyProjectPath, dummyFilePath).then(() => {
          expect(mock.history.get).toHaveLength(1);
        });
      });

      describe('when the method is called with params', () => {
        it('sets the params on the request', () => {
          const params = { ref: 'main' };
          jest.spyOn(axios, 'get');

          Api.getRawFile(dummyProjectPath, dummyFilePath, params);

          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params });
        });
      });

      describe('when the method is called with options', () => {
        it('sets the params and options on the request', () => {
          const options = { responseType: 'text', transformRequest: (x) => x };
          const params = { ref: 'main' };
          jest.spyOn(axios, 'get');

          Api.getRawFile(dummyProjectPath, dummyFilePath, params, options);

          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params, ...options });
        });
      });
    });

    describe('when an error occurs while getting a raw file', () => {
      it('rejects the Promise', () => {
        mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        return Api.getRawFile(dummyProjectPath, dummyFilePath).catch(() => {
          expect(mock.history.get).toHaveLength(1);
        });
      });
    });
  });

  describe('createProjectMergeRequest', () => {
    const dummyProjectPath = 'gitlab-org/gitlab';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
      dummyProjectPath,
    )}/merge_requests`;
    const options = {
      source_branch: 'feature',
      target_branch: 'main',
      title: 'Add feature',
    };

    describe('when the merge request is successfully created', () => {
      it('resolves the Promise', () => {
        mock.onPost(expectedUrl, options).replyOnce(HTTP_STATUS_CREATED);

        return Api.createProjectMergeRequest(dummyProjectPath, options).then(() => {
          expect(mock.history.post).toHaveLength(1);
        });
      });
    });

    describe('when an error occurs while getting a raw file', () => {
      it('rejects the Promise', () => {
        mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        return Api.createProjectMergeRequest(dummyProjectPath).catch(() => {
          expect(mock.history.post).toHaveLength(1);
        });
      });
    });
  });

  describe('updateIssue', () => {
    it('update an issue with the given payload', () => {
      const projectId = 8;
      const issue = 1;
      const expectedArray = [1, 2, 3];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/issues/${issue}`;
      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, { assigneeIds: expectedArray });

      return Api.updateIssue(projectId, issue, { assigneeIds: expectedArray }).then(({ data }) => {
        expect(data.assigneeIds).toEqual(expectedArray);
      });
    });
  });

  describe('updateMergeRequest', () => {
    it('update an issue with the given payload', () => {
      const projectId = 8;
      const mergeRequest = 1;
      const expectedArray = [1, 2, 3];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/merge_requests/${mergeRequest}`;
      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, { assigneeIds: expectedArray });

      return Api.updateMergeRequest(projectId, mergeRequest, { assigneeIds: expectedArray }).then(
        ({ data }) => {
          expect(data.assigneeIds).toEqual(expectedArray);
        },
      );
    });
  });

  describe('tags', () => {
    it('fetches all tags of a particular project', () => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const projectId = 8;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/repository/tags`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      return Api.tags(projectId, query, options).then(({ data }) => {
        expect(data.length).toBe(1);
        expect(data[0].name).toBe('test');
      });
    });
  });

  describe('freezePeriods', () => {
    it('fetches freezePeriods', () => {
      const projectId = 8;
      const freezePeriod = {
        id: 3,
        freeze_start: '5 4 * * *',
        freeze_end: '5 9 * 8 *',
        cron_timezone: 'America/New_York',
        created_at: '2020-07-10T05:10:35.122Z',
        updated_at: '2020-07-10T05:10:35.122Z',
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/freeze_periods`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [freezePeriod]);

      return Api.freezePeriods(projectId).then(({ data }) => {
        expect(data[0]).toStrictEqual(freezePeriod);
      });
    });
  });

  describe('createFreezePeriod', () => {
    const projectId = 8;
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/freeze_periods`;
    const options = {
      freeze_start: '* * * * *',
      freeze_end: '* * * * *',
      cron_timezone: 'America/Juneau',
    };

    const expectedResult = {
      id: 10,
      freeze_start: '* * * * *',
      freeze_end: '* * * * *',
      cron_timezone: 'America/Juneau',
      created_at: '2020-07-11T07:04:50.153Z',
      updated_at: '2020-07-11T07:04:50.153Z',
    };

    describe('when the freeze period is successfully created', () => {
      it('resolves the Promise', () => {
        mock.onPost(expectedUrl, options).replyOnce(HTTP_STATUS_CREATED, expectedResult);

        return Api.createFreezePeriod(projectId, options).then(({ data }) => {
          expect(data).toStrictEqual(expectedResult);
        });
      });
    });
  });

  describe('updateFreezePeriod', () => {
    const options = {
      id: 10,
      freeze_start: '* * * * *',
      freeze_end: '* * * * *',
      cron_timezone: 'America/Juneau',
      created_at: '2020-07-11T07:04:50.153Z',
      updated_at: '2020-07-11T07:04:50.153Z',
    };
    const projectId = 8;
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/freeze_periods/${options.id}`;

    const expectedResult = {
      id: 10,
      freeze_start: '* * * * *',
      freeze_end: '* * * * *',
      cron_timezone: 'America/Juneau',
      created_at: '2020-07-11T07:04:50.153Z',
      updated_at: '2020-07-11T07:04:50.153Z',
    };

    describe('when the freeze period is successfully updated', () => {
      it('resolves the Promise', () => {
        mock.onPut(expectedUrl, options).replyOnce(HTTP_STATUS_OK, expectedResult);

        return Api.updateFreezePeriod(projectId, options).then(({ data }) => {
          expect(data).toStrictEqual(expectedResult);
        });
      });
    });
  });

  describe('createPipeline', () => {
    it('creates new pipeline', () => {
      const redirectUrl = 'ci-project/-/pipelines/95';
      const projectId = 8;
      const postData = {
        ref: 'tag-1',
        variables: [
          { key: 'test_file', value: 'test_file_val', variable_type: 'file' },
          { key: 'test_var', value: 'test_var_val', variable_type: 'env_var' },
        ],
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/pipeline`;

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, {
        web_url: redirectUrl,
      });

      return Api.createPipeline(projectId, postData).then(({ data }) => {
        expect(data.web_url).toBe(redirectUrl);
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData, {
          headers: {
            'Content-Type': 'application/json',
          },
        });
      });
    });
  });

  describe('trackRedisCounterEvent', () => {
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/usage_data/increment_counter`;

    const event = 'dummy_event';
    const postData = { event };
    const headers = {
      'Content-Type': 'application/json',
    };

    describe('when service data increment counter is called', () => {
      it('resolves the Promise', () => {
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl, { event }).replyOnce(HTTP_STATUS_OK, true);

        return Api.trackRedisCounterEvent(event).then(({ data }) => {
          expect(data).toEqual(true);
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData, { headers });
        });
      });
    });
  });

  describe('trackRedisHllUserEvent', () => {
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/usage_data/increment_unique_users`;

    const event = 'dummy_event';
    const postData = { event };
    const headers = {
      'Content-Type': 'application/json',
    };

    describe('when user is set', () => {
      beforeEach(() => {
        window.gon.current_user_id = 1;
      });

      describe('when service data increment unique users is called', () => {
        it('resolves the Promise', () => {
          jest.spyOn(axios, 'post');
          mock.onPost(expectedUrl, { event }).replyOnce(HTTP_STATUS_OK, true);

          return Api.trackRedisHllUserEvent(event).then(({ data }) => {
            expect(data).toEqual(true);
            expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData, { headers });
          });
        });
      });
    });

    describe('when user is not set', () => {
      it('returns null and does not call the endpoint', () => {
        jest.spyOn(axios, 'post');

        const result = Api.trackRedisHllUserEvent(event);

        expect(result).toEqual(null);
        expect(axios.post).toHaveBeenCalledTimes(0);
      });
    });
  });

  describe('trackInternalEvent', () => {
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/usage_data/track_event`;
    const event = 'i_devops_adoption';
    const additionalProperties = { property: 'value' };

    const defaultContext = {
      data: {
        project_id: 123,
        namespace_id: 123,
      },
    };

    const postData = (additionalProps = {}) => ({
      event,
      project_id: defaultContext.data.project_id,
      namespace_id: defaultContext.data.namespace_id,
      additional_properties: additionalProps,
    });

    const headers = {
      'Content-Type': 'application/json',
    };

    describe('when user is set', () => {
      beforeEach(() => {
        window.gon.current_user_id = 1;
        window.gl = { snowplowStandardContext: { ...defaultContext } };
      });

      describe('when internal event is called', () => {
        it('resolves the Promise without additionalProperties', () => {
          jest.spyOn(axios, 'post');
          mock.onPost(expectedUrl, postData()).replyOnce(HTTP_STATUS_OK, true);

          return Api.trackInternalEvent(event).then(({ data }) => {
            expect(data).toEqual(true);
            expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData(), { headers });
          });
        });
      });

      describe('when internal event is called with additionalProperties', () => {
        it('resolves the Promise with additionalProperties', () => {
          jest.spyOn(axios, 'post');
          mock.onPost(expectedUrl, postData(additionalProperties)).replyOnce(HTTP_STATUS_OK, true);

          return Api.trackInternalEvent(event, additionalProperties).then(({ data }) => {
            expect(data).toEqual(true);
            expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData(additionalProperties), {
              headers,
            });
          });
        });
      });
    });
  });

  describe('deployKeys', () => {
    it('fetches deploy keys', async () => {
      const deployKeys = [
        {
          id: 7,
          title: 'My title 1',
          created_at: '2021-10-29T16:59:55.229Z',
          expires_at: null,
          key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDLvQzRX960N7dxPdge9o5a96+M4GEGQ7rxT2D3wAQDtQFjQV5ZcKb5wfeLtYLe3kRVI4lCO10PXeQppb1XBaYmVO31IaRkcgmMEPVyfp76Dp4CJZz6aMEbbcqfaHkDre0Fa8kzTXnBJVh2NeDbBfGMjFM5NRQLhKykodNsepO6dQ== dummy@gitlab.com',
          fingerprint: '81:93:63:b9:1e:24:a2:aa:e0:87:d3:3f:42:81:f2:c2',
          projects_with_write_access: [
            {
              id: 11,
              description: null,
              name: 'project1',
              name_with_namespace: 'John Doe3 / project1',
              path: 'project1',
              path_with_namespace: 'namespace1/project1',
              created_at: '2021-10-29T16:59:54.668Z',
            },
            {
              id: 12,
              description: null,
              name: 'project2',
              name_with_namespace: 'John Doe4 / project2',
              path: 'project2',
              path_with_namespace: 'namespace2/project2',
              created_at: '2021-10-29T16:59:55.116Z',
            },
          ],
        },
      ];

      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/deploy_keys`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, deployKeys);

      const params = { page: 2, public: true };
      const { data } = await Api.deployKeys(params);

      expect(data).toEqual(deployKeys);
      expect(mock.history.get[0].params).toEqual({ ...params, per_page: DEFAULT_PER_PAGE });
    });
  });

  describe('projectSecureFiles', () => {
    it('fetches secure files for a project', async () => {
      const projectId = 1;
      const secureFiles = [
        {
          id: projectId,
          title: 'File Name',
          permissions: 'read_only',
          checksum: '12345',
          checksum_algorithm: 'sha256',
          created_at: '2022-02-21T15:27:18',
        },
      ];

      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/secure_files`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);
      const { data } = await Api.projectSecureFiles(projectId, {});

      expect(data).toEqual(secureFiles);
    });
  });

  describe('uploadProjectSecureFile', () => {
    it('uploads a secure file to a project', async () => {
      const projectId = 1;
      const secureFile = {
        id: projectId,
        title: 'File Name',
        permissions: 'read_only',
        checksum: '12345',
        checksum_algorithm: 'sha256',
        created_at: '2022-02-21T15:27:18',
      };

      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/secure_files`;
      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, secureFile);
      const { data } = await Api.uploadProjectSecureFile(projectId, 'some data');

      expect(data).toEqual(secureFile);
    });
  });

  describe('deleteProjectSecureFile', () => {
    it('removes a secure file from a project', async () => {
      const projectId = 1;
      const secureFileId = 2;

      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/secure_files/${secureFileId}`;
      mock.onDelete(expectedUrl).reply(HTTP_STATUS_NO_CONTENT, '');
      const { data } = await Api.deleteProjectSecureFile(projectId, secureFileId);
      expect(data).toEqual('');
    });
  });

  describe('Feature Flag User List', () => {
    let expectedUrl;
    let projectId;
    let mockUserList;

    beforeEach(() => {
      projectId = 1000;
      expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/feature_flags_user_lists`;
      mockUserList = {
        name: 'mock_user_list',
        user_xids: '1,2,3,4',
        project_id: 1,
        id: 1,
        iid: 1,
      };
    });

    describe('fetchFeatureFlagUserLists', () => {
      it('GETs the right url', () => {
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, []);

        return Api.fetchFeatureFlagUserLists(projectId).then(({ data }) => {
          expect(data).toEqual([]);
        });
      });
    });

    describe('searchFeatureFlagUserLists', () => {
      it('GETs the right url', () => {
        mock.onGet(expectedUrl, { params: { search: 'test' } }).replyOnce(HTTP_STATUS_OK, []);

        return Api.searchFeatureFlagUserLists(projectId, 'test').then(({ data }) => {
          expect(data).toEqual([]);
        });
      });
    });

    describe('createFeatureFlagUserList', () => {
      it('POSTs data to the right url', () => {
        const mockUserListData = {
          name: 'mock_user_list',
          user_xids: '1,2,3,4',
        };
        mock.onPost(expectedUrl, mockUserListData).replyOnce(HTTP_STATUS_OK, mockUserList);

        return Api.createFeatureFlagUserList(projectId, mockUserListData).then(({ data }) => {
          expect(data).toEqual(mockUserList);
        });
      });
    });

    describe('fetchFeatureFlagUserList', () => {
      it('GETs the right url', () => {
        mock.onGet(`${expectedUrl}/1`).replyOnce(HTTP_STATUS_OK, mockUserList);

        return Api.fetchFeatureFlagUserList(projectId, 1).then(({ data }) => {
          expect(data).toEqual(mockUserList);
        });
      });
    });

    describe('updateFeatureFlagUserList', () => {
      it('PUTs the right url', () => {
        mock
          .onPut(`${expectedUrl}/1`)
          .replyOnce(HTTP_STATUS_OK, { ...mockUserList, user_xids: '5' });

        return Api.updateFeatureFlagUserList(projectId, {
          ...mockUserList,
          user_xids: '5',
        }).then(({ data }) => {
          expect(data).toEqual({ ...mockUserList, user_xids: '5' });
        });
      });
    });

    describe('deleteFeatureFlagUserList', () => {
      it('DELETEs the right url', () => {
        mock.onDelete(`${expectedUrl}/1`).replyOnce(HTTP_STATUS_OK, 'deleted');

        return Api.deleteFeatureFlagUserList(projectId, 1).then(({ data }) => {
          expect(data).toBe('deleted');
        });
      });
    });
  });

  describe('projectProtectedBranch', () => {
    const branchName = 'new-branch-name';
    const dummyProjectId = 5;
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${dummyProjectId}/protected_branches/${branchName}`;

    it('returns 404 for non-existing branch', () => {
      jest.spyOn(axios, 'get');

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_NOT_FOUND, {
        message: '404 Not found',
      });

      return Api.projectProtectedBranch(dummyProjectId, branchName).catch((error) => {
        expect(error.response.status).toBe(HTTP_STATUS_NOT_FOUND);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
      });
    });

    it('returns 200 with branch information', () => {
      const expectedObj = { name: branchName };

      jest.spyOn(axios, 'get');

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedObj);

      return Api.projectProtectedBranch(dummyProjectId, branchName).then((data) => {
        expect(data).toEqual(expectedObj);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
      });
    });
  });
});
