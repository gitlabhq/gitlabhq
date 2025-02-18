import groups from 'test_fixtures/api/groups/groups/shared/get.json';
import SharedGroupsService from '~/groups/service/shared_groups_service';
import { getSharedGroups } from '~/rest_api';
import { ITEM_TYPE } from '~/groups/constants';

jest.mock('~/rest_api');

describe('SharedGroupsService', () => {
  const groupId = 1;
  let service;

  beforeEach(() => {
    service = new SharedGroupsService(groupId, 'created_asc');
  });

  describe('getGroups', () => {
    const headers = { 'x-next-page': '2', 'x-page': '1', 'x-per-page': '20' };
    const page = 2;
    const query = 'git';
    const sort = 'created_asc';

    it('returns a promise that resolves with formatted groups', async () => {
      getSharedGroups.mockResolvedValueOnce({ data: groups, headers });

      await expect(service.getGroups(undefined, page, query, sort)).resolves.toEqual({
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
      });

      expect(getSharedGroups).toHaveBeenCalledWith(groupId, {
        page,
        order_by: 'name',
        sort: 'asc',
        search: query,
      });
    });
  });
});
