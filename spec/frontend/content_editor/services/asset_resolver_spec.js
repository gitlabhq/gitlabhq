import AssetResolver from '~/content_editor/services/asset_resolver';
import {
  RESOLVED_ISSUE_HTML,
  RESOLVED_MERGE_REQUEST_HTML,
  RESOLVED_EPIC_HTML,
} from '../test_constants';

describe('content_editor/services/asset_resolver', () => {
  let renderMarkdown;
  let assetResolver;

  beforeEach(() => {
    renderMarkdown = jest.fn();
    assetResolver = new AssetResolver({ renderMarkdown });
  });

  describe('resolveUrl', () => {
    it('resolves a canonical url to an absolute url', async () => {
      renderMarkdown.mockResolvedValue(
        '<p><a href="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png">link</a></p>',
      );

      expect(await assetResolver.resolveUrl('test-file.png')).toBe(
        '/group1/project1/-/wikis/test-file.png',
      );
    });
  });

  describe('resolveReference', () => {
    const resolvedEpic = {
      expandedText: 'Approvals in merge request list (&1)',
      fullyExpandedText: 'Approvals in merge request list (&1)',
      href: '/groups/gitlab-org/-/epics/1',
      text: '&1',
    };

    const resolvedIssue = {
      expandedText: '500 error on MR approvers edit page (#1 - closed)',
      fullyExpandedText: '500 error on MR approvers edit page (#1 - closed) • Unassigned',
      href: '/gitlab-org/gitlab/-/issues/1',
      text: '#1 (closed)',
    };

    const resolvedMergeRequest = {
      expandedText: 'Enhance the LDAP group synchronization (!1 - merged)',
      fullyExpandedText: 'Enhance the LDAP group synchronization (!1 - merged) • John Doe',
      href: '/gitlab-org/gitlab/-/merge_requests/1',
      text: '!1 (merged)',
    };

    describe.each`
      referenceType      | referenceId | sentMarkdown     | returnedHtml                   | resolvedReference
      ${'issue'}         | ${'#1'}     | ${'#1 #1+ #1+s'} | ${RESOLVED_ISSUE_HTML}         | ${resolvedIssue}
      ${'merge_request'} | ${'!1'}     | ${'!1 !1+ !1+s'} | ${RESOLVED_MERGE_REQUEST_HTML} | ${resolvedMergeRequest}
      ${'epic'}          | ${'&1'}     | ${'&1 &1+ &1+s'} | ${RESOLVED_EPIC_HTML}          | ${resolvedEpic}
    `(
      'for reference type $referenceType',
      ({ referenceType, referenceId, sentMarkdown, returnedHtml, resolvedReference }) => {
        it(`resolves ${referenceType} reference to href, text, title and summary`, async () => {
          renderMarkdown.mockResolvedValue(returnedHtml);

          expect(await assetResolver.resolveReference(referenceId)).toEqual(resolvedReference);
        });

        it.each`
          suffix
          ${''}
          ${'+'}
          ${'+s'}
        `('strips suffix ("$suffix") before resolving', ({ suffix }) => {
          assetResolver.resolveReference(referenceId + suffix);
          expect(renderMarkdown).toHaveBeenCalledWith(sentMarkdown);
        });
      },
    );

    it.each`
      case                              | sentMarkdown        | returnedHtml
      ${'no html is returned'}          | ${''}               | ${''}
      ${'html contains no anchor tags'} | ${'no anchor tags'} | ${'<p>no anchor tags</p>'}
    `('returns an empty object if $case', async ({ sentMarkdown, returnedHtml }) => {
      renderMarkdown.mockResolvedValue(returnedHtml);

      expect(await assetResolver.resolveReference(sentMarkdown)).toEqual({});
    });
  });

  describe('renderDiagram', () => {
    it('resolves a diagram code to a url containing the diagram image', async () => {
      renderMarkdown.mockResolvedValue(
        '<p><img data-diagram="nomnoml" src="url/to/some/diagram"></p>',
      );

      expect(await assetResolver.renderDiagram('test')).toBe('url/to/some/diagram');
    });
  });
});
