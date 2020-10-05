import { generateBadges } from '~/vue_shared/components/members/utils';
import { member as memberMock } from './mock_data';

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
});
