import Api from '~/api';

export default class InactiveProjectsService {
  constructor(groupId, initialSort) {
    this.groupId = groupId;
    this.initialSort = initialSort;
  }

  // eslint-disable-next-line max-params
  async getGroups(parentId, page, query, sortParam) {
    const supportedOrderBy = {
      name: 'name',
      created: 'created_at',
      latest_activity: 'last_activity_at',
    };

    const [, orderBy, sort] = (sortParam || this.initialSort)?.match(/(\w+)_(asc|desc)/) || [];

    const { data: projects, headers } = await Api.groupProjects(this.groupId, query, {
      archived: true,
      include_subgroups: true,
      page,
      order_by: supportedOrderBy[orderBy],
      sort,
    });

    return {
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
          marked_for_deletion: Boolean(project.marked_for_deletion_at),
          last_activity_at: project.last_activity_at,
          archived: project.archived,
        };
      }),
      headers,
    };
  }
}
