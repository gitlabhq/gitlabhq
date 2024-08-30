import { cloneDeep } from 'lodash';
import MockAdapter from 'axios-mock-adapter';
import { roleDropdownItems } from '~/members/utils';
import {
  getRoleDropdownItems,
  getMemberRole,
  callRoleUpdateApi,
  setMemberRole,
} from '~/members/components/table/drawer/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { member as memberMock } from '../../../mock_data';

const getRoles = (member) => roleDropdownItems(member).flatten;

describe('Role details drawer utils', () => {
  describe('getRoleDropdownItems', () => {
    it('returns dropdown items', () => {
      expect(getRoleDropdownItems).toBe(roleDropdownItems);
    });
  });

  describe('getMemberRole', () => {
    const roles = getRoles(memberMock);

    it.each(roles)('returns $text role for member', (expectedRole) => {
      const member = cloneDeep(memberMock);
      member.accessLevel.integerValue = expectedRole.accessLevel;
      const role = getMemberRole(roles, member);

      expect(role).toBe(expectedRole);
    });
  });

  describe('callRoleUpdateApi', () => {
    it.each`
      namespace  | propertyName
      ${'user'}  | ${'access_level'}
      ${'group'} | ${'group_access'}
    `(
      'calls update API with expected data for $namespace namespace',
      async ({ namespace, propertyName }) => {
        const memberPath = 'member/path/123';
        const mockAxios = new MockAdapter(axios);
        mockAxios.onPut(memberPath).replyOnce(HTTP_STATUS_OK);

        const member = { ...memberMock, memberPath, namespace };
        const role = getRoles(member)[1];
        await callRoleUpdateApi(member, role);

        expect(mockAxios.history.put).toHaveLength(1);
        expect(mockAxios.history.put[0].data).toBe(
          JSON.stringify({ [propertyName]: 10, member_role_id: null }),
        );
      },
    );
  });

  describe('setMemberRole', () => {
    const roles = getRoles(memberMock);

    it.each(roles)('updates member access level for role $text', (role) => {
      const member = cloneDeep(memberMock);
      setMemberRole(member, role);

      expect(member.accessLevel).toEqual({
        stringValue: role.text,
        integerValue: role.accessLevel,
        description: role.description,
        memberRoleId: role.memberRoleId,
      });
    });
  });
});
