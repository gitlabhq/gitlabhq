import { builders } from 'prosemirror-test-builder';
import Reference from '~/content_editor/extensions/reference';
import ReferenceLabel from '~/content_editor/extensions/reference_label';
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
  RESOLVED_USER_WITH_DOTS_HTML,
  REPOSITORY_RELATIVE_LINK_HTML,
  REPOSITORY_RELATIVE_IMAGE_HTML,
  UPLOAD_IMAGE_HTML,
  LINK_REFERENCE_HTML,
} from '../test_constants';
import { createTestEditor, triggerNodeInputRule, waitUntilTransaction } from '../test_utils';

// Every reference filter in lib/banzai/filter/references (CE and EE) plus the reference
// type of the personal snippet filter; each emits `class="gfm gfm-<type>"` together with
// `data-reference-type="<type>"`.
const BACKEND_REFERENCE_TYPES = [
  'alert',
  'commit',
  'commit_range',
  'design',
  'epic',
  'external_issue',
  'feature_flag',
  'issue',
  'iteration',
  'iterations_cadence',
  'merge_request',
  'milestone',
  'project',
  'snippet',
  'user',
  'vulnerability',
  'wiki_page',
  'work_item',
];

describe('content_editor/extensions/reference', () => {
  let tiptapEditor;
  let doc;
  let p;
  let reference;
  let referenceLabel;
  let renderMarkdown;
  let assetResolver;

  beforeEach(() => {
    renderMarkdown = jest.fn().mockImplementation(() => new Promise(() => {}));
    assetResolver = new AssetResolver({ renderMarkdown });

    tiptapEditor = createTestEditor({
      extensions: [Reference.configure({ assetResolver }), ReferenceLabel],
    });

    ({ doc, paragraph: p, reference, referenceLabel } = builders(tiptapEditor.schema));
  });

  describe('when typing a valid reference input rule', () => {
    // eslint-disable-next-line max-params
    const buildExpectedDoc = (href, originalText, referenceType, text = originalText) =>
      doc(p(reference({ className: null, href, originalText, referenceType, text }), ' '));

    // eslint-disable-next-line max-params
    const buildExpectedDocForLabel = (href, originalText, text, color) =>
      doc(
        p(
          referenceLabel({
            className: null,
            referenceType: 'label',
            href,
            originalText,
            text,
            color,
          }),
          ' ',
        ),
      );

    it.each`
      inputRuleText          | mockReferenceHtml              | expectedDoc
      ${'#1'}                | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1', 'issue', '#1 (closed)')}
      ${'#1+'}               | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1+', 'issue', '500 error on MR approvers edit page (#1 - closed)')}
      ${'#1+s'}              | ${RESOLVED_ISSUE_HTML}         | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/issues/1', '#1+s', 'issue', '500 error on MR approvers edit page (#1 - closed) • Unassigned')}
      ${'!1'}                | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1', 'merge_request', '!1 (merged)')}
      ${'!1+'}               | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1+', 'merge_request', 'Enhance the LDAP group synchronization (!1 - merged)')}
      ${'!1+s'}              | ${RESOLVED_MERGE_REQUEST_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab/-/merge_requests/1', '!1+s', 'merge_request', 'Enhance the LDAP group synchronization (!1 - merged) • John Doe')}
      ${'&1'}                | ${RESOLVED_EPIC_HTML}          | ${() => buildExpectedDoc('/groups/gitlab-org/-/epics/1', '&1', 'epic', '&1')}
      ${'&1+'}               | ${RESOLVED_EPIC_HTML}          | ${() => buildExpectedDoc('/groups/gitlab-org/-/epics/1', '&1+', 'epic', 'Approvals in merge request list (&1)')}
      ${'@root'}             | ${RESOLVED_USER_HTML}          | ${() => buildExpectedDoc('/root', '@root', 'user')}
      ${'~Aquanix'}          | ${RESOLVED_LABEL_HTML}         | ${() => buildExpectedDocForLabel('/gitlab-org/gitlab-shell/-/issues?label_name=Aquanix', '~Aquanix', 'Aquanix', 'rgb(230, 84, 49)')}
      ${'%v4.0'}             | ${RESOLVED_MILESTONE_HTML}     | ${() => buildExpectedDoc('/gitlab-org/gitlab-shell/-/milestones/5', '%v4.0', 'milestone')}
      ${'$25'}               | ${RESOLVED_SNIPPET_HTML}       | ${() => buildExpectedDoc('/gitlab-org/gitlab-shell/-/snippets/25', '$25', 'snippet')}
      ${'[vulnerability:1]'} | ${RESOLVED_VULNERABILITY_HTML} | ${() => buildExpectedDoc('/gitlab-org/gitlab-shell/-/security/vulnerabilities/1', '[vulnerability:1]', 'vulnerability')}
    `(
      'replaces the input rule ($inputRuleText) with a reference node',
      async ({ inputRuleText, mockReferenceHtml, expectedDoc }) => {
        await waitUntilTransaction({
          number: 2,
          tiptapEditor,
          action() {
            renderMarkdown.mockResolvedValueOnce({ body: mockReferenceHtml });

            tiptapEditor.commands.insertContent({ type: 'text', text: `${inputRuleText} ` });
            triggerNodeInputRule({ tiptapEditor, inputRuleText: `${inputRuleText} ` });
          },
        });

        expect(tiptapEditor.getJSON()).toEqual(expectedDoc().toJSON());
      },
    );

    it('resolves references correctly around punctuation', async () => {
      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce({ body: RESOLVED_USER_HTML });

          tiptapEditor.commands.insertContent({ type: 'text', text: '@root, could you help?' });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: '@root,' });
        },
      });

      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          p(
            reference({
              referenceType: 'user',
              originalText: '@root',
              text: '@root',
              href: '/root',
            }),
            ', could you help?',
          ),
        ).toJSON(),
      );
    });

    it('resolves references correctly around parenthesis', async () => {
      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce({ body: RESOLVED_USER_HTML });

          tiptapEditor.commands.insertContent({
            type: 'text',
            text: 'Lets ask Administrator (@root) for help here',
          });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: '(@root)' });
        },
      });

      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          p(
            'Lets ask Administrator (',
            reference({
              referenceType: 'user',
              originalText: '@root',
              text: '@root',
              href: '/root',
            }),
            ') for help here',
          ),
        ).toJSON(),
      );
    });

    it('correctly resolves references with dots in them', async () => {
      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce({ body: RESOLVED_USER_WITH_DOTS_HTML });

          tiptapEditor.commands.insertContent({
            type: 'text',
            text: 'Lets ask @root.with.dots for help here',
          });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: '@root.with.dots' });
        },
      });

      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          p(
            'Lets ask ',
            reference({
              referenceType: 'user',
              originalText: '@root.with.dots',
              text: '@root.with.dots',
              href: '/root.with.dots',
            }),
            ' for help here',
          ),
        ).toJSON(),
      );
    });

    it('resolves multiple references in the same paragraph correctly', async () => {
      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce({ body: RESOLVED_ISSUE_HTML });

          tiptapEditor.commands.insertContent({ type: 'text', text: '#1+ ' });
          triggerNodeInputRule({ tiptapEditor, inputRuleText: '#1+ ' });
        },
      });

      await waitUntilTransaction({
        number: 2,
        tiptapEditor,
        action() {
          renderMarkdown.mockResolvedValueOnce({ body: RESOLVED_MERGE_REQUEST_HTML });

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
        resolvePromise = (body) => resolve({ body });
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

  describe('parseHTML', () => {
    it.each(BACKEND_REFERENCE_TYPES)(
      'parses an anchor with data-reference-type="%s" as a reference node',
      (referenceType) => {
        tiptapEditor.commands.setContent(
          `<p><a href="/path" class="gfm gfm-${referenceType}" data-reference-type="${referenceType}" data-original="ref">ref text</a></p>`,
        );

        expect(tiptapEditor.getJSON()).toEqual(
          doc(
            p(
              reference({
                className: `gfm gfm-${referenceType}`,
                referenceType,
                originalText: 'ref',
                href: '/path',
                text: 'ref text',
              }),
            ),
          ).toJSON(),
        );
      },
    );

    it('parses a label as a label reference node', () => {
      tiptapEditor.commands.setContent(RESOLVED_LABEL_HTML);

      expect(tiptapEditor.getJSON().content[0].content[0]).toMatchObject({
        type: 'referenceLabel',
        attrs: { referenceType: 'label', originalText: '~Aquanix', text: 'Aquanix' },
      });
    });

    it.each`
      description                                    | html                              | expectedDoc
      ${'a link to a file in the repository'}        | ${REPOSITORY_RELATIVE_LINK_HTML}  | ${() => doc(p('readme'))}
      ${'an image from the repository'}              | ${REPOSITORY_RELATIVE_IMAGE_HTML} | ${() => doc(p())}
      ${'an uploaded image'}                         | ${UPLOAD_IMAGE_HTML}              | ${() => doc(p())}
      ${'a link whose text differs from its target'} | ${LINK_REFERENCE_HTML}            | ${() => doc(p('the issue'))}
    `('does not parse $description as a reference', ({ html, expectedDoc }) => {
      tiptapEditor.commands.setContent(html);

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc().toJSON());
    });
  });
});
