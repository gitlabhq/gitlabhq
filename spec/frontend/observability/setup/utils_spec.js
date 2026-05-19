import { extractHost, generateSnippet, goSnippet } from '~/observability/setup/utils';
import { LANGUAGES } from '~/observability/setup/constants';

describe('observability/setup/utils', () => {
  describe('extractHost', () => {
    it.each([
      ['https://observe.gitlab.com', 'observe.gitlab.com'],
      ['http://localhost:4318', 'localhost:4318'],
      ['https://example.com/path', 'example.com/path'],
    ])('extracts host from %s', (input, expected) => {
      expect(extractHost(input)).toBe(expected);
    });
  });

  describe('generateSnippet', () => {
    const endpoint = 'https://observe.gitlab.com';

    it.each(LANGUAGES.map((l) => l.key))(
      'generates a non-empty snippet containing the endpoint for %s',
      (key) => {
        const snippet = generateSnippet(key, endpoint);
        expect(snippet.length).toBeGreaterThan(0);
        expect(snippet).toContain('observe.gitlab.com');
      },
    );

    it('returns empty string for unknown key', () => {
      expect(generateSnippet('unknown', endpoint)).toBe('');
    });
  });

  describe('goSnippet', () => {
    it.each([
      ['https://observe.gitlab.com', 'observe.gitlab.com'],
      ['http://localhost:4318', 'localhost:4318'],
    ])('strips the protocol from %s', (endpoint, expectedHost) => {
      expect(goSnippet(endpoint)).toContain(`WithEndpoint("${expectedHost}")`);
    });
  });
});
