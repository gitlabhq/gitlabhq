import projects from 'test_fixtures/api/groups/projects/get.json';
import InactiveProjectsService from '~/groups/service/inactive_projects_service';
import Api from '~/api';

jest.mock('~/api');

describe('InactiveProjectsService', () => {
  const groupId = 1;
  let service;

  beforeEach(() => {
    service = new InactiveProjectsService(groupId, 'name_asc');
  });

  describe('getGroups', () => {
    const headers = { 'x-next-page': '2', 'x-page': '1', 'x-per-page': '20' };
    const page = 2;
    const query = 'git';
    const sort = 'created_asc';

    it('returns promise the resolves with formatted project', async () => {
      Api.groupProjects.mockResolvedValueOnce({ data: projects, headers });

      await expect(service.getGroups(undefined, page, query, sort)).resolves.toEqual({
        data: projects.map((project) => {
          return {
            id: project.id,
            name: project.name,
            full_name: project.name_with_namespace,
            markdown_description: project.description_html,
            visibility: project.visibility,
            avatar_url: project.avatar_url,
            relative_path: `${gon.relative_url_root}/${project.path_with_namespace}`,
            edit_path: null,
            leave_path: null,
            can_edit: false,
            can_leave: false,
            can_remove: false,
            type: 'project',
            permission: null,
            children: [],
            parent_id: project.namespace.id,
            project_count: 0,
            subgroup_count: 0,
            number_users_with_delimiter: 0,
            star_count: project.star_count,
            updated_at: project.updated_at,
            marked_for_deletion: false,
            last_activity_at: project.last_activity_at,
            archived: false,
          };
        }),
        headers,
      });

      expect(Api.groupProjects).toHaveBeenCalledWith(groupId, query, {
        archived: true,
        include_subgroups: true,
        page,
        order_by: 'created_at',
        sort: 'asc',
      });
    });

    describe.each`
      markedForDeletionAt | expected
      ${null}             | ${false}
      ${undefined}        | ${false}
      ${'2023-07-21'}     | ${true}
    `(
      'when `marked_for_deletion_at` is $markedForDeletionAt',
      ({ markedForDeletionAt, expected }) => {
        it(`sets marked_for_deletion to ${expected}`, async () => {
          Api.groupProjects.mockResolvedValueOnce({
            data: projects.map((project) => ({
              ...project,
              marked_for_deletion_at: markedForDeletionAt,
            })),
            headers,
          });

          await expect(service.getGroups(undefined, page, query, sort)).resolves.toMatchObject({
            data: projects.map(() => {
              return {
                marked_for_deletion: expected,
              };
            }),
            headers,
          });
        });
      },
    );

    describe.each`
      sortArgument              | expectedOrderByParameter | expectedSortParameter
      ${'name_asc'}             | ${'name'}                | ${'asc'}
      ${'name_desc'}            | ${'name'}                | ${'desc'}
      ${'created_asc'}          | ${'created_at'}          | ${'asc'}
      ${'created_desc'}         | ${'created_at'}          | ${'desc'}
      ${'latest_activity_asc'}  | ${'last_activity_at'}    | ${'asc'}
      ${'latest_activity_desc'} | ${'last_activity_at'}    | ${'desc'}
      ${undefined}              | ${'name'}                | ${'asc'}
    `(
      'when the sort argument is $sortArgument',
      ({ sortArgument, expectedSortParameter, expectedOrderByParameter }) => {
        it(`calls the API with sort parameter set to ${expectedSortParameter} and order_by parameter set to ${expectedOrderByParameter}`, () => {
          Api.groupProjects.mockResolvedValueOnce({ data: projects, headers });

          service.getGroups(undefined, page, query, sortArgument);

          expect(Api.groupProjects).toHaveBeenCalledWith(groupId, query, {
            archived: true,
            include_subgroups: true,
            page,
            order_by: expectedOrderByParameter,
            sort: expectedSortParameter,
          });
        });
      },
    );
  });
});
