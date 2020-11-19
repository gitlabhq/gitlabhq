import {
  generateBadges,
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canResend,
  canUpdate,
  canOverride,
} from '~/members/utils';
import { member as memberMock, group, invite } from './mock_data';

const DIRECT_MEMBER_ID = 178;
const INHERITED_MEMBER_ID = 179;
const IS_CURRENT_USER_ID = 123;
const IS_NOT_CURRENT_USER_ID = 124;

describe('Members Utils', () => {
  describe('generateBadges', () => {
    it('has correct properties for each badge', () => {
      const badges = generateBadges(memberMock, true);

      badges.forEach(badge => {
        expect(badge).toEqual(
          expect.objectContaining({
            show: expect.any(Boolean),
            text: expect.any(String),
            variant: expect.stringMatching(/muted|neutral|info|success|danger|warning/),
          }),
        );
      });
    });

    it.each`
      member                                                                     | expected
      ${memberMock}                                                              | ${{ show: true, text: "It's you", variant: 'success' }}
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }}          | ${{ show: true, text: 'Blocked', variant: 'danger' }}
      ${{ ...memberMock, user: { ...memberMock.user, twoFactorEnabled: true } }} | ${{ show: true, text: '2FA', variant: 'info' }}
    `('returns expected output for "$expected.text" badge', ({ member, expected }) => {
      expect(generateBadges(member, true)).toContainEqual(expect.objectContaining(expected));
    });
  });

  describe('isGroup', () => {
    test.each`
      member        | expected
      ${group}      | ${true}
      ${memberMock} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(isGroup(member)).toBe(expected);
    });
  });

  describe('isDirectMember', () => {
    test.each`
      sourceId               | expected
      ${DIRECT_MEMBER_ID}    | ${true}
      ${INHERITED_MEMBER_ID} | ${false}
    `('returns $expected', ({ sourceId, expected }) => {
      expect(isDirectMember(memberMock, sourceId)).toBe(expected);
    });
  });

  describe('isCurrentUser', () => {
    test.each`
      currentUserId             | expected
      ${IS_CURRENT_USER_ID}     | ${true}
      ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ currentUserId, expected }) => {
      expect(isCurrentUser(memberMock, currentUserId)).toBe(expected);
    });
  });

  describe('canRemove', () => {
    const memberCanRemove = {
      ...memberMock,
      canRemove: true,
    };

    test.each`
      member             | sourceId               | expected
      ${memberCanRemove} | ${DIRECT_MEMBER_ID}    | ${true}
      ${memberCanRemove} | ${INHERITED_MEMBER_ID} | ${false}
      ${memberMock}      | ${INHERITED_MEMBER_ID} | ${false}
    `('returns $expected', ({ member, sourceId, expected }) => {
      expect(canRemove(member, sourceId)).toBe(expected);
    });
  });

  describe('canResend', () => {
    test.each`
      member                                                           | expected
      ${invite}                                                        | ${true}
      ${{ ...invite, invite: { ...invite.invite, canResend: false } }} | ${false}
    `('returns $expected', ({ member, sourceId, expected }) => {
      expect(canResend(member, sourceId)).toBe(expected);
    });
  });

  describe('canUpdate', () => {
    const memberCanUpdate = {
      ...memberMock,
      canUpdate: true,
    };

    test.each`
      member             | currentUserId             | sourceId               | expected
      ${memberCanUpdate} | ${IS_NOT_CURRENT_USER_ID} | ${DIRECT_MEMBER_ID}    | ${true}
      ${memberCanUpdate} | ${IS_CURRENT_USER_ID}     | ${DIRECT_MEMBER_ID}    | ${false}
      ${memberCanUpdate} | ${IS_CURRENT_USER_ID}     | ${INHERITED_MEMBER_ID} | ${false}
      ${memberMock}      | ${IS_NOT_CURRENT_USER_ID} | ${DIRECT_MEMBER_ID}    | ${false}
    `('returns $expected', ({ member, currentUserId, sourceId, expected }) => {
      expect(canUpdate(member, currentUserId, sourceId)).toBe(expected);
    });
  });

  describe('canOverride', () => {
    it('returns `false`', () => {
      expect(canOverride(memberMock)).toBe(false);
    });
  });
});
