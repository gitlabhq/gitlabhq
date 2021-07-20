import MockAdapter from 'axios-mock-adapter';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
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

  describe('packages', () => {
    const projectId = 'project_a';
    const packageId = 'package_b';
    const apiResponse = [{ id: 1, name: 'foo' }];

    describe('groupPackages', () => {
      const groupId = 'group_a';

      it('fetch all group packages', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/packages`;
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

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
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

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
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

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
        mock.onDelete(expectedUrl).replyOnce(httpStatus.OK, true);

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
        mock.onDelete(expectedUrl).replyOnce(httpStatus.OK, true);

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
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

        const { data } = await Api.containerRegistryDetails(1);

        expect(data).toEqual(apiResponse);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
      });
    });
  });

  describe('group', () => {
    it('fetches a group', (done) => {
      const groupId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        name: 'test',
      });

      Api.group(groupId, (response) => {
        expect(response.name).toBe('test');
        done();
      });
    });
  });

  describe('groupMembers', () => {
    it('fetches group members', (done) => {
      const groupId = '54321';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/members`;
      const expectedData = [{ id: 7 }];
      mock.onGet(expectedUrl).reply(httpStatus.OK, expectedData);

      Api.groupMembers(groupId)
        .then(({ data }) => {
          expect(data).toEqual(expectedData);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('addGroupMembersByUserId', () => {
    it('adds an existing User as a new Group Member by User ID', () => {
      const groupId = 1;
      const expectedUserId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/1/members`;
      const params = {
        user_id: expectedUserId,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(200, {
        id: expectedUserId,
        state: 'active',
      });

      return Api.addGroupMembersByUserId(groupId, params).then(({ data }) => {
        expect(data.id).toBe(expectedUserId);
        expect(data.state).toBe('active');
      });
    });
  });

  describe('inviteGroupMembersByEmail', () => {
    it('invites a new email address to create a new User and become a Group Member', () => {
      const groupId = 1;
      const email = 'email@example.com';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/1/invitations`;
      const params = {
        email,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(200, {
        status: 'success',
      });

      return Api.inviteGroupMembersByEmail(groupId, params).then(({ data }) => {
        expect(data.status).toBe('success');
      });
    });
  });

  describe('groupMilestones', () => {
    it('fetches group milestones', (done) => {
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
      mock.onGet(expectedUrl).reply(httpStatus.OK, expectedData);

      Api.groupMilestones(groupId)
        .then(({ data }) => {
          expect(data).toEqual(expectedData);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('groups', () => {
    it('fetches groups', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups.json`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.groups(query, options, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('groupLabels', () => {
    it('fetches group labels', (done) => {
      const options = { params: { search: 'foo' } };
      const expectedGroup = 'gitlab-org';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${expectedGroup}/labels`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          id: 1,
          name: 'Foo Label',
        },
      ]);

      Api.groupLabels(expectedGroup, options)
        .then((res) => {
          expect(res.length).toBe(1);
          expect(res[0].name).toBe('Foo Label');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('namespaces', () => {
    it('fetches namespaces', (done) => {
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/namespaces.json`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.namespaces(query, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('projects', () => {
    it('fetches projects with membership when logged in', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      window.gon.current_user_id = 1;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.projects(query, options, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });

    it('fetches projects without membership when not logged in', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.projects(query, options, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('updateProject', () => {
    it('update a project with the given payload', (done) => {
      const projectPath = 'foo';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}`;
      mock.onPut(expectedUrl).reply(httpStatus.OK, { foo: 'bar' });

      Api.updateProject(projectPath, { foo: 'bar' })
        .then(({ data }) => {
          expect(data.foo).toBe('bar');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('projectUsers', () => {
    it('fetches all users of a particular project', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const projectPath = 'gitlab-org%2Fgitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/users`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.projectUsers('gitlab-org/gitlab-ce', query, options)
        .then((response) => {
          expect(response.length).toBe(1);
          expect(response[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequests', () => {
    const projectPath = 'abc';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests`;

    it('fetches all merge requests for a project', (done) => {
      const mockData = [{ source_branch: 'foo' }, { source_branch: 'bar' }];
      mock.onGet(expectedUrl).reply(httpStatus.OK, mockData);
      Api.projectMergeRequests(projectPath)
        .then(({ data }) => {
          expect(data.length).toEqual(2);
          expect(data[0].source_branch).toBe('foo');
          expect(data[1].source_branch).toBe('bar');
        })
        .then(done)
        .catch(done.fail);
    });

    it('fetches merge requests filtered with passed params', (done) => {
      const params = {
        source_branch: 'bar',
      };
      const mockData = [{ source_branch: 'bar' }];
      mock.onGet(expectedUrl, { params }).reply(httpStatus.OK, mockData);

      Api.projectMergeRequests(projectPath, params)
        .then(({ data }) => {
          expect(data.length).toEqual(1);
          expect(data[0].source_branch).toBe('bar');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequest', () => {
    it('fetches a merge request', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        title: 'test',
      });

      Api.projectMergeRequest(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequestChanges', () => {
    it('fetches the changes of a merge request', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/changes`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        title: 'test',
      });

      Api.projectMergeRequestChanges(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequestVersions', () => {
    it('fetches the versions of a merge request', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/versions`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          id: 123,
        },
      ]);

      Api.projectMergeRequestVersions(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].id).toBe(123);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectRunners', () => {
    it('fetches the runners of a project', (done) => {
      const projectPath = 7;
      const params = { scope: 'active' };
      const mockData = [{ id: 4 }];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/runners`;
      mock.onGet(expectedUrl, { params }).reply(httpStatus.OK, mockData);

      Api.projectRunners(projectPath, { params })
        .then(({ data }) => {
          expect(data).toEqual(mockData);
        })
        .then(done)
        .catch(done.fail);
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
      };

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).reply(200, {
        status: 'success',
      });

      return Api.projectShareWithGroup(projectId, options).then(({ data }) => {
        expect(data.status).toBe('success');
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, options);
      });
    });
  });

  describe('projectMilestones', () => {
    it('fetches project milestones', (done) => {
      const projectId = 1;
      const options = { state: 'active' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/milestones`;
      mock.onGet(expectedUrl).reply(200, [
        {
          id: 1,
          title: 'milestone1',
          state: 'active',
        },
      ]);

      Api.projectMilestones(projectId, options)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].title).toBe('milestone1');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('addProjectIssueAsTodo', () => {
    it('adds issue ID as a todo', () => {
      const projectId = 1;
      const issueIid = 11;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/issues/11/todo`;
      mock.onPost(expectedUrl).reply(200, {
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

  describe('addProjectMembersByUserId', () => {
    it('adds an existing User as a new Project Member by User ID', () => {
      const projectId = 1;
      const expectedUserId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/members`;
      const params = {
        user_id: expectedUserId,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(200, {
        id: expectedUserId,
        state: 'active',
      });

      return Api.addProjectMembersByUserId(projectId, params).then(({ data }) => {
        expect(data.id).toBe(expectedUserId);
        expect(data.state).toBe('active');
      });
    });
  });

  describe('inviteProjectMembersByEmail', () => {
    it('invites a new email address to create a new User and become a Project Member', () => {
      const projectId = 1;
      const expectedEmail = 'email@example.com';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/1/invitations`;
      const params = {
        email: expectedEmail,
        access_level: 10,
        expires_at: undefined,
      };

      mock.onPost(expectedUrl).reply(200, {
        status: 'success',
      });

      return Api.inviteProjectMembersByEmail(projectId, params).then(({ data }) => {
        expect(data.status).toBe('success');
      });
    });
  });

  describe('newLabel', () => {
    it('creates a new project label', (done) => {
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
          httpStatus.OK,
          {
            name: 'test',
          },
        ];
      });

      Api.newLabel(namespace, project, labelData, (response) => {
        expect(response.name).toBe('test');
        done();
      });
    });

    it('creates a new group label', (done) => {
      const namespace = 'group/subgroup';
      const labelData = { name: 'Foo', color: '#000000' };
      const expectedUrl = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespace);
      mock.onPost(expectedUrl).reply((config) => {
        expect(config.data).toBe(JSON.stringify({ color: labelData.color }));

        return [
          httpStatus.OK,
          {
            ...labelData,
          },
        ];
      });

      Api.newLabel(namespace, undefined, labelData, (response) => {
        expect(response.name).toBe('Foo');
        done();
      });
    });
  });

  describe('groupProjects', () => {
    it('fetches group projects', (done) => {
      const groupId = '123456';
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/projects.json`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.groupProjects(groupId, query, {}, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
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

      mock.onPost(expectedUrl).reply(200, {
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
      mock.onGet(expectedUrl).reply(httpStatus.OK, { id: sha });

      return Api.commit(projectId, sha).then(({ data: commit }) => {
        expect(commit.id).toBe(sha);
      });
    });

    it('fetches a single commit without stats', () => {
      mock.onGet(expectedUrl, { params: { stats: false } }).reply(httpStatus.OK, { id: sha });

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

    it('fetches an issue template', (done) => {
      mock.onGet(expectedUrl).reply(httpStatus.OK, 'test');

      Api.issueTemplate(namespace, project, templateKey, templateType, (error, response) => {
        expect(response).toBe('test');
        done();
      });
    });

    describe('when an error occurs while fetching an issue template', () => {
      it('rejects the Promise', () => {
        mock.onGet(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

        Api.issueTemplate(namespace, project, templateKey, templateType, () => {
          expect(mock.history.get).toHaveLength(1);
        });
      });
    });
  });

  describe('issueTemplates', () => {
    const namespace = 'some namespace';
    const project = 'some project';
    const templateType = 'template type';
    const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/templates/${templateType}`;

    it('fetches all templates by type', (done) => {
      const expectedData = [
        { key: 'Template1', name: 'Template 1', content: 'This is template 1!' },
      ];
      mock.onGet(expectedUrl).reply(httpStatus.OK, expectedData);

      Api.issueTemplates(namespace, project, templateType, (error, response) => {
        expect(response.length).toBe(1);
        const { key, name, content } = response[0];
        expect(key).toBe('Template1');
        expect(name).toBe('Template 1');
        expect(content).toBe('This is template 1!');
        done();
      });
    });

    describe('when an error occurs while fetching issue templates', () => {
      it('rejects the Promise', () => {
        mock.onGet(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

        Api.issueTemplates(namespace, project, templateType, () => {
          expect(mock.history.get).toHaveLength(1);
        });
      });
    });
  });

  describe('projectTemplates', () => {
    it('fetches a list of templates', (done) => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses`;

      mock.onGet(expectedUrl).reply(httpStatus.OK, 'test');

      Api.projectTemplates('gitlab-org/gitlab-ce', 'licenses', {}, (response) => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('projectTemplate', () => {
    it('fetches a single template', (done) => {
      const data = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses/test%20license`;

      mock.onGet(expectedUrl).reply(httpStatus.OK, 'test');

      Api.projectTemplate('gitlab-org/gitlab-ce', 'licenses', 'test license', data, (response) => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('users', () => {
    it('fetches users', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users.json`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.users(query, options)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('user', () => {
    it('fetches single user', (done) => {
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        name: 'testuser',
      });

      Api.user(userId)
        .then(({ data }) => {
          expect(data.name).toBe('testuser');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('user counts', () => {
    it('fetches single user counts', (done) => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/user_counts`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        merge_requests: 4,
      });

      Api.userCounts()
        .then(({ data }) => {
          expect(data.merge_requests).toBe(4);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('user status', () => {
    it('fetches single user status', (done) => {
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}/status`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, {
        message: 'testmessage',
      });

      Api.userStatus(userId)
        .then(({ data }) => {
          expect(data.message).toBe('testmessage');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('user projects', () => {
    it('fetches all projects that belong to a particular user', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const userId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users/${userId}/projects`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.userProjects(userId, query, options, (response) => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('commitPipelines', () => {
    it('fetches pipelines for a given commit', (done) => {
      const projectId = 'example/foobar';
      const commitSha = 'abc123def';
      const expectedUrl = `${dummyUrlRoot}/${projectId}/commit/${commitSha}/pipelines`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.commitPipelines(projectId, commitSha)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('pipelineJobs', () => {
    it.each([undefined, {}, { foo: true }])(
      'fetches the jobs for a given pipeline given %p params',
      async (params) => {
        const projectId = 123;
        const pipelineId = 456;
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/pipelines/${pipelineId}/jobs`;
        const payload = [
          {
            name: 'test',
          },
        ];
        mock.onGet(expectedUrl, { params }).reply(httpStatus.OK, payload);

        const { data } = await Api.pipelineJobs(projectId, pipelineId, params);
        expect(data).toEqual(payload);
      },
    );
  });

  describe('createBranch', () => {
    it('creates new branch', (done) => {
      const ref = 'main';
      const branch = 'new-branch-name';
      const dummyProjectPath = 'gitlab-org/gitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
        dummyProjectPath,
      )}/repository/branches`;

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(httpStatus.OK, {
        name: branch,
      });

      Api.createBranch(dummyProjectPath, { ref, branch })
        .then(({ data }) => {
          expect(data.name).toBe(branch);
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, { ref, branch });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectForks', () => {
    it('gets forked projects', (done) => {
      const dummyProjectPath = 'gitlab-org/gitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
        dummyProjectPath,
      )}/forks`;

      jest.spyOn(axios, 'get');

      mock.onGet(expectedUrl).replyOnce(httpStatus.OK, ['fork']);

      Api.projectForks(dummyProjectPath, { visibility: 'private' })
        .then(({ data }) => {
          expect(data).toEqual(['fork']);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
            params: { visibility: 'private' },
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('createContextCommits', () => {
    it('creates a new context commit', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const commitsData = ['abcdefg'];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;
      const expectedData = {
        commits: commitsData,
      };

      jest.spyOn(axios, 'post');

      mock.onPost(expectedUrl).replyOnce(200, [
        {
          id: 'abcdefghijklmnop',
          short_id: 'abcdefg',
          title: 'Dummy commit',
        },
      ]);

      Api.createContextCommits(projectPath, mergeRequestId, expectedData)
        .then(({ data }) => {
          expect(data[0].title).toBe('Dummy commit');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('allContextCommits', () => {
    it('gets all context commits', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;

      jest.spyOn(axios, 'get');

      mock
        .onGet(expectedUrl)
        .replyOnce(200, [{ id: 'abcdef', short_id: 'abcdefghi', title: 'Dummy commit title' }]);

      Api.allContextCommits(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data[0].title).toBe('Dummy commit title');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('removeContextCommits', () => {
    it('removes context commits', (done) => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const commitsData = ['abcdefg'];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/context_commits`;
      const expectedData = {
        commits: commitsData,
      };

      jest.spyOn(axios, 'delete');

      mock.onDelete(expectedUrl).replyOnce(204);

      Api.removeContextCommits(projectPath, mergeRequestId, expectedData)
        .then(() => {
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl, { data: expectedData });
        })
        .then(done)
        .catch(done.fail);
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
          mock.onGet(expectedUrl).replyOnce(httpStatus.OK);

          return Api.releases(dummyProjectPath).then(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while fetching releases', () => {
        it('rejects the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
          mock.onGet(expectedUrl).replyOnce(httpStatus.OK);

          return Api.release(dummyProjectPath, dummyTagName).then(() => {
            expect(mock.history.get).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while fetching the release', () => {
        it('rejects the Promise', () => {
          mock.onGet(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
          mock.onPost(expectedUrl, release).replyOnce(httpStatus.CREATED);

          return Api.createRelease(dummyProjectPath, release).then(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while creating the release', () => {
        it('rejects the Promise', () => {
          mock.onPost(expectedUrl, release).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
          mock.onPut(expectedUrl, release).replyOnce(httpStatus.OK);

          return Api.updateRelease(dummyProjectPath, dummyTagName, release).then(() => {
            expect(mock.history.put).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while updating the release', () => {
        it('rejects the Promise', () => {
          mock.onPut(expectedUrl, release).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
          mock.onPost(expectedUrl, expectedLink).replyOnce(httpStatus.CREATED);

          return Api.createReleaseLink(dummyProjectPath, dummyTagName, expectedLink).then(() => {
            expect(mock.history.post).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while creating the Release', () => {
        it('rejects the Promise', () => {
          mock.onPost(expectedUrl, expectedLink).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
          mock.onDelete(expectedUrl).replyOnce(httpStatus.OK);

          return Api.deleteReleaseLink(dummyProjectPath, dummyTagName, dummyLinkId).then(() => {
            expect(mock.history.delete).toHaveLength(1);
          });
        });
      });

      describe('when an error occurs while deleting the Release', () => {
        it('rejects the Promise', () => {
          mock.onDelete(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK);
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
    });

    describe('when an error occurs while getting a raw file', () => {
      it('rejects the Promise', () => {
        mock.onPost(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

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
        mock.onPost(expectedUrl, options).replyOnce(httpStatus.CREATED);

        return Api.createProjectMergeRequest(dummyProjectPath, options).then(() => {
          expect(mock.history.post).toHaveLength(1);
        });
      });
    });

    describe('when an error occurs while getting a raw file', () => {
      it('rejects the Promise', () => {
        mock.onPost(expectedUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);

        return Api.createProjectMergeRequest(dummyProjectPath).catch(() => {
          expect(mock.history.post).toHaveLength(1);
        });
      });
    });
  });

  describe('updateIssue', () => {
    it('update an issue with the given payload', (done) => {
      const projectId = 8;
      const issue = 1;
      const expectedArray = [1, 2, 3];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/issues/${issue}`;
      mock.onPut(expectedUrl).reply(httpStatus.OK, { assigneeIds: expectedArray });

      Api.updateIssue(projectId, issue, { assigneeIds: expectedArray })
        .then(({ data }) => {
          expect(data.assigneeIds).toEqual(expectedArray);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('updateMergeRequest', () => {
    it('update an issue with the given payload', (done) => {
      const projectId = 8;
      const mergeRequest = 1;
      const expectedArray = [1, 2, 3];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/merge_requests/${mergeRequest}`;
      mock.onPut(expectedUrl).reply(httpStatus.OK, { assigneeIds: expectedArray });

      Api.updateMergeRequest(projectId, mergeRequest, { assigneeIds: expectedArray })
        .then(({ data }) => {
          expect(data.assigneeIds).toEqual(expectedArray);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('tags', () => {
    it('fetches all tags of a particular project', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const projectId = 8;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/repository/tags`;
      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.tags(projectId, query, options)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
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
      mock.onGet(expectedUrl).reply(httpStatus.OK, [freezePeriod]);

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
        mock.onPost(expectedUrl, options).replyOnce(httpStatus.CREATED, expectedResult);

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
        mock.onPut(expectedUrl, options).replyOnce(httpStatus.OK, expectedResult);

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

      mock.onPost(expectedUrl).replyOnce(httpStatus.OK, {
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

    describe('when service data increment counter is called with feature flag disabled', () => {
      beforeEach(() => {
        gon.features = { ...gon.features, usageDataApi: false };
      });

      it('returns null', () => {
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl).replyOnce(httpStatus.OK, true);

        expect(axios.post).toHaveBeenCalledTimes(0);
        expect(Api.trackRedisCounterEvent(event)).toEqual(null);
      });
    });

    describe('when service data increment counter is called', () => {
      beforeEach(() => {
        gon.features = { ...gon.features, usageDataApi: true };
      });

      it('resolves the Promise', () => {
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl, { event }).replyOnce(httpStatus.OK, true);

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

      describe('when service data increment unique users is called with feature flag disabled', () => {
        beforeEach(() => {
          gon.features = { ...gon.features, usageDataApi: false };
        });

        it('returns null and does not call the endpoint', () => {
          jest.spyOn(axios, 'post');

          const result = Api.trackRedisHllUserEvent(event);

          expect(result).toEqual(null);
          expect(axios.post).toHaveBeenCalledTimes(0);
        });
      });

      describe('when service data increment unique users is called', () => {
        beforeEach(() => {
          gon.features = { ...gon.features, usageDataApi: true };
        });

        it('resolves the Promise', () => {
          jest.spyOn(axios, 'post');
          mock.onPost(expectedUrl, { event }).replyOnce(httpStatus.OK, true);

          return Api.trackRedisHllUserEvent(event).then(({ data }) => {
            expect(data).toEqual(true);
            expect(axios.post).toHaveBeenCalledWith(expectedUrl, postData, { headers });
          });
        });
      });
    });

    describe('when user is not set and feature flag enabled', () => {
      beforeEach(() => {
        gon.features = { ...gon.features, usageDataApi: true };
      });

      it('returns null and does not call the endpoint', () => {
        jest.spyOn(axios, 'post');

        const result = Api.trackRedisHllUserEvent(event);

        expect(result).toEqual(null);
        expect(axios.post).toHaveBeenCalledTimes(0);
      });
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
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        return Api.fetchFeatureFlagUserLists(projectId).then(({ data }) => {
          expect(data).toEqual([]);
        });
      });
    });

    describe('searchFeatureFlagUserLists', () => {
      it('GETs the right url', () => {
        mock.onGet(expectedUrl, { params: { search: 'test' } }).replyOnce(httpStatus.OK, []);

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
        mock.onPost(expectedUrl, mockUserListData).replyOnce(httpStatus.OK, mockUserList);

        return Api.createFeatureFlagUserList(projectId, mockUserListData).then(({ data }) => {
          expect(data).toEqual(mockUserList);
        });
      });
    });

    describe('fetchFeatureFlagUserList', () => {
      it('GETs the right url', () => {
        mock.onGet(`${expectedUrl}/1`).replyOnce(httpStatus.OK, mockUserList);

        return Api.fetchFeatureFlagUserList(projectId, 1).then(({ data }) => {
          expect(data).toEqual(mockUserList);
        });
      });
    });

    describe('updateFeatureFlagUserList', () => {
      it('PUTs the right url', () => {
        mock
          .onPut(`${expectedUrl}/1`)
          .replyOnce(httpStatus.OK, { ...mockUserList, user_xids: '5' });

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
        mock.onDelete(`${expectedUrl}/1`).replyOnce(httpStatus.OK, 'deleted');

        return Api.deleteFeatureFlagUserList(projectId, 1).then(({ data }) => {
          expect(data).toBe('deleted');
        });
      });
    });
  });
});
