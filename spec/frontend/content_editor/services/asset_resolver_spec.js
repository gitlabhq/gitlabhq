import AssetResolver from '~/content_editor/services/asset_resolver';
import {
  RESOLVED_ISSUE_HTML,
  RESOLVED_MERGE_REQUEST_HTML,
  RESOLVED_EPIC_HTML,
  RESOLVED_LABEL_HTML,
  RESOLVED_SNIPPET_HTML,
  RESOLVED_MILESTONE_HTML,
  RESOLVED_USER_HTML,
  RESOLVED_VULNERABILITY_HTML,
} from '../test_constants';

const labelCamryHtml = `<span class="gl-label"><a class="gfm gfm-label has-tooltip gl-link gl-label-link" title="" data-placement="top" data-container="body" data-project="7" data-label="101" data-link-reference="false" data-link="false" data-original="~101" data-reference-type="label" href="/gitlab-org/gitlab-test/-/issues?label_name=Camry"><span style="background-color: #e88c97" data-html="true" data-container="body" class="gl-label-text gl-label-text-light">Camry</span></a></span>`;
const labelCorollaWagonHtml = `<span class="gl-label"><a class="gfm gfm-label has-tooltip gl-link gl-label-link" title="" data-placement="top" data-container="body" data-project="7" data-label="104" data-link-reference="false" data-link="false" data-original="~104" data-reference-type="label" href="/gitlab-org/gitlab-test/-/issues?label_name=Corolla+Wagon"><span style="background-color: #23d305" data-html="true" data-container="body" class="gl-label-text gl-label-text-dark">Corolla Wagon</span></a></span>`;
const labelBriostHtml = `<span class="gl-label"><a class="gfm gfm-label has-tooltip gl-link gl-label-link" title="" data-placement="top" data-container="body" data-project="7" data-label="59" data-link-reference="false" data-link="false" data-original="~59" data-reference-type="label" href="/gitlab-org/gitlab-test/-/issues?label_name=Briost"><span style="background-color: #cb8d88" data-html="true" data-container="body" class="gl-label-text gl-label-text-light">Briost</span></a></span>`;

describe('content_editor/services/asset_resolver', () => {
  let renderMarkdown;
  let assetResolver;

  beforeEach(() => {
    renderMarkdown = jest.fn();
    assetResolver = new AssetResolver({ renderMarkdown });
  });

  describe('resolveUrl', () => {
    it('resolves a canonical url to an absolute url', async () => {
      renderMarkdown.mockResolvedValue({
        body: '<p><a href="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png">link</a></p>',
      });

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

    const resolvedLabel = {
      backgroundColor: 'rgb(230, 84, 49)',
      href: '/gitlab-org/gitlab-shell/-/issues?label_name=Aquanix',
      text: 'Aquanix',
    };

    const resolvedSnippet = {
      href: '/gitlab-org/gitlab-shell/-/snippets/25',
      text: '$25',
    };

    const resolvedMilestone = {
      href: '/gitlab-org/gitlab-shell/-/milestones/5',
      text: '%v4.0',
    };

    const resolvedUser = {
      href: '/root',
      text: '@root',
    };

    const resolvedVulnerability = {
      href: '/gitlab-org/gitlab-shell/-/security/vulnerabilities/1',
      text: '[vulnerability:1]',
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
          renderMarkdown.mockResolvedValue({ body: returnedHtml });

          expect(await assetResolver.resolveReference(referenceId)).toMatchObject(
            resolvedReference,
          );
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

    describe.each`
      referenceType      | referenceId            | returnedHtml                   | resolvedReference
      ${'label'}         | ${'~Aquanix'}          | ${RESOLVED_LABEL_HTML}         | ${resolvedLabel}
      ${'snippet'}       | ${'$25'}               | ${RESOLVED_SNIPPET_HTML}       | ${resolvedSnippet}
      ${'milestone'}     | ${'%v4.0'}             | ${RESOLVED_MILESTONE_HTML}     | ${resolvedMilestone}
      ${'user'}          | ${'@root'}             | ${RESOLVED_USER_HTML}          | ${resolvedUser}
      ${'vulnerability'} | ${'[vulnerability:1]'} | ${RESOLVED_VULNERABILITY_HTML} | ${resolvedVulnerability}
    `(
      'for reference type $referenceType',
      ({ referenceType, referenceId, returnedHtml, resolvedReference }) => {
        it(`resolves ${referenceType} reference to href, text and additional props (if any)`, async () => {
          renderMarkdown.mockResolvedValue({ body: returnedHtml });

          expect(await assetResolver.resolveReference(referenceId)).toMatchObject(
            resolvedReference,
          );
        });
      },
    );

    it.each`
      case                              | sentMarkdown        | returnedHtml
      ${'no html is returned'}          | ${''}               | ${''}
      ${'html contains no anchor tags'} | ${'no anchor tags'} | ${'<p>no anchor tags</p>'}
    `('returns an empty object if $case', async ({ sentMarkdown, returnedHtml }) => {
      renderMarkdown.mockResolvedValue({ body: returnedHtml });

      expect(await assetResolver.resolveReference(sentMarkdown)).toEqual({});
    });
  });

  describe('explainQuickAction', () => {
    it('resolves a quick action to a text explanation', async () => {
      renderMarkdown.mockResolvedValue({
        references: {
          commands: '<p>Closes the issue.</p>',
        },
      });

      expect(await assetResolver.explainQuickAction('/close')).toBe('Closes the issue.');
    });

    it('resolves to empty string if no explanation is present', async () => {
      renderMarkdown.mockResolvedValue();

      expect(await assetResolver.explainQuickAction('/close')).toBe('');
    });

    it.each`
      text                                   | resolvedHtml                                                                             | result
      ${'/label ~Camry'}                     | ${`<p>Adds ${labelCamryHtml} label.</p>`}                                                | ${'Adds a label.'}
      ${'/label ~Camry ~"Corolla Wagon"'}    | ${`<p>Adds ${labelCamryHtml} ${labelCorollaWagonHtml} labels.</p>`}                      | ${'Adds 2 labels.'}
      ${'/unlabel ~Briost'}                  | ${`<p>Removes ${labelBriostHtml} label.</p>`}                                            | ${'Removes a label.'}
      ${'/unlabel ~Briost ~"Corolla Wagon"'} | ${`<p>Removes ${labelBriostHtml} ${labelCorollaWagonHtml} labels.</p>`}                  | ${'Removes 2 labels.'}
      ${'/relabel ~Briost'}                  | ${`<p>Replaces all labels with ${labelBriostHtml} label.</p>`}                           | ${'Replaces all labels with 1 label.'}
      ${'/relabel ~Briost ~"Corolla Wagon"'} | ${`<p>Replaces all labels with ${labelBriostHtml} ${labelCorollaWagonHtml} labels.</p>`} | ${'Replaces all labels with 2 labels.'}
    `('resolves explanation of \'$text\' to "$result"', async ({ text, resolvedHtml, result }) => {
      renderMarkdown.mockResolvedValue({ references: { commands: resolvedHtml } });

      expect(await assetResolver.explainQuickAction(text)).toBe(result);
    });
  });

  describe('renderDiagram', () => {
    it('resolves a diagram code to a url containing the diagram image', async () => {
      renderMarkdown.mockResolvedValue({
        body: '<p><img data-diagram="nomnoml" src="url/to/some/diagram"></p>',
      });

      expect(await assetResolver.renderDiagram('test')).toBe('url/to/some/diagram');
    });
  });
});
