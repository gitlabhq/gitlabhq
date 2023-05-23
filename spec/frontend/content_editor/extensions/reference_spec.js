import Reference from '~/content_editor/extensions/reference';
import AssetResolver from '~/content_editor/services/asset_resolver';
import {
  RESOLVED_ISSUE_HTML,
  RESOLVED_MERGE_REQUEST_HTML,
  RESOLVED_EPIC_HTML,
} from '../test_constants';
import {
  createTestEditor,
  createDocBuilder,
  triggerNodeInputRule,
  waitUntilTransaction,
} from '../test_utils';

describe('content_editor/extensions/reference', () => {
  let tiptapEditor;
  let doc;
  let p;
  let reference;
  let renderMarkdown;
  let assetResolver;

  beforeEach(() => {
    renderMarkdown = jest.fn().mockImplementation(() => new Promise(() => {}));
    assetResolver = new AssetResolver({ renderMarkdown });

    tiptapEditor = createTestEditor({
      extensions: [Reference.configure({ assetResolver })],
    });

    ({
      builders: { doc, p, reference },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        reference: { nodeType: Reference.name },
      },
    }));
  });

  describe('when typing a valid reference input rule', () => {
    const buildExpectedDoc = (href, originalText, referenceType, text) =>
      doc(p(reference({ className: null, href, originalText, referenceType, text }), ' '));

    it.each`
      inputRuleText | mockReferenceHtml              | expectedDoc
      ${'#1 '}      | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1', 'issue', '#1 (closed)')}
      ${'#1+ '}     | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1+', 'issue', '500 error on MR approvers edit page (#1 - closed)')}
      ${'#1+s '}    | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1+s', 'issue', '500 error on MR approvers edit page (#1 - closed) • Unassigned')}
      ${'!1 '}      | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1', 'merge_request', '!1 (merged)')}
      ${'!1+ '}     | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1+', 'merge_request', 'Enhance the LDAP group synchronization (!1 - merged)')}
      ${'!1+s '}    | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1+s', 'merge_request', 'Enhance the LDAP group synchronization (!1 - merged) • John Doe')}
      ${'&1 '}      | ${RESOLVED_EPIC_HTML}          | ${() => buildExpectedDoc('/groups/gitlab-org/-/epics/1', '&1', 'epic', '&1')}
      ${'&1+ '}     | ${RESOLVED_EPIC_HTML}          | ${() => buildExpectedDoc('/groups/gitlab-org/-/epics/1', '&1+', 'epic', 'Approvals in merge request list (&1)')}
    `(
      'replaces the input rule ($inputRuleText) with a reference node',
      async ({ inputRuleText, mockReferenceHtml, expectedDoc }) => {
        await waitUntilTransaction({
          number: 2,
          tiptapEditor,
          action() {
            renderMarkdown.mockResolvedValueOnce(mockReferenceHtml);

            tiptapEditor.commands.insertContent({ type: 'text', text: inputRuleText });
            triggerNodeInputRule({ tiptapEditor, inputRuleText });
          },
        });

        expect(tiptapEditor.getJSON()).toEqual(expectedDoc().toJSON());
      },
    );

    it('resolves multiple references in the same paragraph correctly', async () => {
      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce(RESOLVED_ISSUE_HTML);

          tiptapEditor.commands.insertContent({ type: 'text', text: '#1+ ' });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: '#1+ ' });
        },
      });

      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce(RESOLVED_MERGE_REQUEST_HTML);

          tiptapEditor.commands.insertContent({ type: 'text', text: 'was resolved with !1+ ' });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: 'was resolved with !1+ ' });
        },
      });

      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          p(
            reference({
              referenceType: 'issue',
              originalText: '#1+',
              text: '500 error on MR approvers edit page (#1 - closed)',
              href: '/gitlab-org/gitlab/-/issues/1',
            }),
            ' was resolved with ',
            reference({
              referenceType: 'merge_request',
              originalText: '!1+',
              text: 'Enhance the LDAP group synchronization (!1 - merged)',
              href: '/gitlab-org/gitlab/-/merge_requests/1',
            }),
            ' ',
          ),
        ).toJSON(),
      );
    });

    it('resolves the input rule lazily in the correct position if the user makes a change before the request resolves', async () => {
      let resolvePromise;
      const promise = new Promise((resolve) => {
        resolvePromise = resolve;
      });

      renderMarkdown.mockImplementation(() => promise);

      tiptapEditor.commands.insertContent({ type: 'text', text: '#1+ ' });
      triggerNodeInputRule({ tiptapEditor, inputRuleText: '#1+ ' });

      // insert a new paragraph at a random location
      tiptapEditor.commands.insertContentAt(0, {
        type: 'paragraph',
        content: [{ type: 'text', text: 'Hello' }],
      });

      // update selection
      tiptapEditor.commands.selectAll();

      await waitUntilTransaction({
        number: 1,
        tiptapEditor,
        action() {
          resolvePromise(RESOLVED_ISSUE_HTML);
        },
      });

      expect(tiptapEditor.state.doc).toEqual(
        doc(
          p('Hello'),
          p(
            reference({
              referenceType: 'issue',
              originalText: '#1+',
              text: '500 error on MR approvers edit page (#1 - closed)',
              href: '/gitlab-org/gitlab/-/issues/1',
            }),
            ' ',
          ),
        ),
      );
    });
  });
});
