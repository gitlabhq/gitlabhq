import { showPasskeySignIn } from '~/authentication/sign_in/utils';

describe('showPasskeySignIn', () => {
  it('returns true', () => {
    expect(showPasskeySignIn()).toBe(true);
  });
});
