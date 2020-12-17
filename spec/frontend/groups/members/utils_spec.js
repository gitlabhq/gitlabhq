import { membersJsonString, membersParsed } from './mock_data';
import {
  parseDataAttributes,
  memberRequestFormatter,
  groupLinkRequestFormatter,
} from '~/groups/members/utils';

describe('group member utils', () => {
  describe('parseDataAttributes', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.setAttribute('data-members', membersJsonString);
      el.setAttribute('data-group-id', '234');
      el.setAttribute('data-can-manage-members', 'true');
    });

    afterEach(() => {
      el = null;
    });

    it('correctly parses the data attributes', () => {
      expect(parseDataAttributes(el)).toEqual({
        members: membersParsed,
        sourceId: 234,
        canManageMembers: true,
      });
    });
  });

  describe('memberRequestFormatter', () => {
    it('returns expected format', () => {
      expect(
        memberRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
        }),
      ).toEqual({ group_member: { access_level: 50, expires_at: '2020-10-16' } });
    });
  });

  describe('groupLinkRequestFormatter', () => {
    it('returns expected format', () => {
      expect(
        groupLinkRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
        }),
      ).toEqual({ group_link: { group_access: 50, expires_at: '2020-10-16' } });
    });
  });
});
