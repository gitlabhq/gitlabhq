import crypto from 'crypto';

import { createCodeVerifier, createCodeChallenge } from '~/jira_connect/subscriptions/pkce';

describe('pkce', () => {
  beforeAll(() => {
    Object.defineProperty(global.self, 'crypto', {
      value: {
        getRandomValues: (arr) => crypto.randomBytes(arr.length),
        subtle: {
          digest: jest.fn().mockResolvedValue(new ArrayBuffer(1)),
        },
      },
    });
  });

  describe('createCodeVerifier', () => {
    it('calls `window.crypto.getRandomValues`', () => {
      window.crypto.getRandomValues = jest.fn();
      createCodeVerifier();

      expect(window.crypto.getRandomValues).toHaveBeenCalled();
    });

    it(`returns a string with 128 characters`, () => {
      const codeVerifier = createCodeVerifier();
      expect(codeVerifier).toHaveLength(128);
    });
  });

  describe('createCodeChallenge', () => {
    it('calls `window.crypto.subtle.digest` with correct arguments', async () => {
      await createCodeChallenge('1234');

      expect(window.crypto.subtle.digest).toHaveBeenCalledWith('SHA-256', expect.anything());
    });

    it('returns base64 URL-encoded string', async () => {
      const codeChallenge = await createCodeChallenge('1234');

      expect(codeChallenge).toBe('AA');
    });
  });
});
