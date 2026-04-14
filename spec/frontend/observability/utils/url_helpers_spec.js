import { buildIframeUrl, extractTargetPath } from '~/observability/utils/url_helpers';

describe('URL Helper Utilities', () => {
  describe('buildIframeUrl', () => {
    it.each`
      description                                   | path                            | baseUrl                       | expected
      ${'combines relative paths with base URL'}    | ${'/dashboards'}                | ${'https://example.com'}      | ${'https://example.com/dashboards'}
      ${'combines relative paths with base URL'}    | ${'/dashboards/123/metrics'}    | ${'https://example.com'}      | ${'https://example.com/dashboards/123/metrics'}
      ${'preserves query parameters'}               | ${'/dashboards?tab=metrics'}    | ${'https://example.com'}      | ${'https://example.com/dashboards?tab=metrics'}
      ${'preserves fragments'}                      | ${'/dashboards#overview'}       | ${'https://example.com'}      | ${'https://example.com/dashboards#overview'}
      ${'handles absolute URLs by using directly'}  | ${'https://other.com/absolute'} | ${'https://example.com'}      | ${'https://other.com/absolute'}
      ${'handles base URLs with existing paths'}    | ${'/dashboards'}                | ${'https://example.com/base'} | ${'https://example.com/dashboards'}
      ${'handles base URLs with ports'}             | ${'/dashboards'}                | ${'https://example.com:8080'} | ${'https://example.com:8080/dashboards'}
      ${'handles root paths'}                       | ${'/'}                          | ${'https://example.com'}      | ${'https://example.com/'}
      ${'returns base URL when construction fails'} | ${'invalid-path'}               | ${'invalid-base-url'}         | ${'invalid-base-url'}
    `('$description: $path + $baseUrl = $expected', ({ path, baseUrl, expected }) => {
      expect(buildIframeUrl(path, baseUrl)).toBe(expected);
    });

    it('returns null when baseUrl is empty', () => {
      expect(buildIframeUrl('/dashboards', '')).toBeNull();
    });

    describe('with extraParams', () => {
      it('appends extra params to a path with no existing query string', () => {
        const extra = new URLSearchParams('tab=overview&search=foo');
        expect(buildIframeUrl('/dashboards', 'https://example.com', extra)).toBe(
          'https://example.com/dashboards?tab=overview&search=foo',
        );
      });

      it('merges extra params with params already present on the path without duplication', () => {
        const extra = new URLSearchParams('search=new');

        expect(buildIframeUrl('/dashboards?tab=metrics', 'https://example.com', extra)).toBe(
          'https://example.com/dashboards?tab=metrics&search=new',
        );
      });

      it('does not duplicate a param that is already on the path', () => {
        const extra = new URLSearchParams('tab=new');
        const result = buildIframeUrl('/dashboards?tab=metrics', 'https://example.com', extra);
        const url = new URL(result);

        expect(url.searchParams.getAll('tab')).toHaveLength(1);
      });

      it('returns the base URL unchanged when extraParams is null', () => {
        expect(buildIframeUrl('/dashboards', 'https://example.com', null)).toBe(
          'https://example.com/dashboards',
        );
      });
    });
  });

  describe('extractTargetPath', () => {
    it.each`
      description                                        | path                            | baseUrl                  | expected
      ${'extracts pathname from combined URL'}           | ${'/dashboards/123/metrics'}    | ${'https://example.com'} | ${'/dashboards/123/metrics'}
      ${'extracts pathname from root'}                   | ${'/'}                          | ${'https://example.com'} | ${'/'}
      ${'ignores query parameters'}                      | ${'/dashboards?tab=metrics'}    | ${'https://example.com'} | ${'/dashboards'}
      ${'ignores fragments'}                             | ${'/dashboards#overview'}       | ${'https://example.com'} | ${'/dashboards'}
      ${'extracts pathname from absolute URLs'}          | ${'https://other.com/absolute'} | ${'https://example.com'} | ${'/absolute'}
      ${'returns original path when construction fails'} | ${'invalid-path'}               | ${'invalid-base-url'}    | ${'invalid-path'}
    `('$description: $path + $baseUrl = $expected', ({ path, baseUrl, expected }) => {
      expect(extractTargetPath(path, baseUrl)).toBe(expected);
    });

    it('returns null when path is empty', () => {
      expect(extractTargetPath('', 'https://example.com')).toBeNull();
    });
  });
});
