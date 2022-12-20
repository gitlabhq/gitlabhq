import { guestOverageConfirmAction } from '~/members/guest_overage_confirm_action';

describe('guestOverageConfirmAction', () => {
  it('returns true', () => {
    expect(guestOverageConfirmAction()).toBe(true);
  });
});
