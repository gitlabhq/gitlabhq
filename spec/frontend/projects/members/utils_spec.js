import { projectMemberRequestFormatter } from '~/projects/members/utils';

describe('project member utils', () => {
  describe('projectMemberRequestFormatter', () => {
    it('returns expected format', () => {
      expect(
        projectMemberRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
        }),
      ).toEqual({ project_member: { access_level: 50, expires_at: '2020-10-16' } });
    });
  });
});
