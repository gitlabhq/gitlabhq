import { groupMemberRequestFormatter } from '~/groups/members/utils';

describe('group member utils', () => {
  describe('groupMemberRequestFormatter', () => {
    it('returns expected format', () => {
      expect(
        groupMemberRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
        }),
      ).toEqual({
        group_member: { access_level: 50, expires_at: '2020-10-16', member_role_id: null },
      });

      expect(
        groupMemberRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
          memberRoleId: 80,
        }),
      ).toEqual({
        group_member: { access_level: 50, expires_at: '2020-10-16', member_role_id: 80 },
      });
    });
  });
});
