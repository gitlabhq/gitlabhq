import { getSharedGroups } from '~/rest_api';
import { ITEM_TYPE } from '../constants';

export default class SharedGroupsService {
  constructor(groupId, initialSort) {
    this.groupId = groupId;
    this.initialSort = initialSort;
  }

  // eslint-disable-next-line max-params
  async getGroups(parentId, page, query, sortParam) {
    const [, sort] = (sortParam || this.initialSort)?.match(/\w+_(asc|desc)/) || [];

    const { data: groups, headers } = await getSharedGroups(this.groupId, {
      page,
      order_by: 'name',
      sort,
      search: query,
    });

    return {
      data: groups.map((group) => {
        return {
          id: group.id,
          name: group.name,
          full_name: group.full_name,
          markdown_description: group.description,
          visibility: group.visibility,
          avatar_url: group.avatar_url,
          relative_path: `${gon.relative_url_root}/${group.full_path}`,
          edit_path: null,
          leave_path: null,
          can_edit: false,
          can_leave: false,
          can_remove: false,
          type: ITEM_TYPE.GROUP,
          permission: null,
          children: [],
          parent_id: group.parent_id,
        };
      }),
      headers,
    };
  }
}
