import { getOAuthConfig } from '~/ide/lib/gitlab_web_ide/get_oauth_config';
import { getMockCallbackUrl } from 'jest/ide/helpers';

describe('~/ide/lib/gitlab_web_ide/get_oauth_config', () => {
  it('returns undefined if no clientId found', () => {
    expect(getOAuthConfig({})).toBeUndefined();
  });

  it('returns auth config from dataset', () => {
    expect(getOAuthConfig({ clientId: 'test-clientId' })).toEqual({
      type: 'oauth',
      clientId: 'test-clientId',
      callbackUrl: getMockCallbackUrl(),
      protectRefreshToken: true,
    });
  });
});
