import { builders } from 'prosemirror-test-builder';
import Link from '~/content_editor/extensions/link';
import { createTestEditor, triggerMarkInputRule } from '../test_utils';

const GFM_LINK_HTML =
  '<p data-sourcepos="1:1-1:63" dir="auto"><a href="https://gitlab.com/gitlab-org/gitlab-test/-/issues/1" data-reference-type="issue" data-original="test" data-link="true" data-link-reference="true" data-issue="11" data-project="2" data-iid="1" data-namespace-path="gitlab-org/gitlab-test" data-project-path="gitlab-org/gitlab-test" data-issue-type="issue" data-container="body" data-placement="top" title="Rerum vero repellat saepe sunt ullam provident." class="gfm gfm-issue">test</a></p>';

describe('content_editor/extensions/link', () => {
  let tiptapEditor;
  let doc;
  let p;
  let link;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Link] });
    ({ doc, paragraph: p, link } = builders(tiptapEditor.schema));
  });

  it.each`
    input                             | insertedNode
    ${'[gitlab](https://gitlab.com)'} | ${() => p(link({ href: 'https://gitlab.com' }, 'gitlab'))}
    ${'[documentation](readme.md)'}   | ${() => p(link({ href: 'readme.md' }, 'documentation'))}
    ${'[link 123](readme.md)'}        | ${() => p(link({ href: 'readme.md' }, 'link 123'))}
    ${'[link 123](read me.md)'}       | ${() => p(link({ href: 'read me.md' }, 'link 123'))}
    ${'text'}                         | ${() => p('text')}
    ${'documentation](readme.md'}     | ${() => p('documentation](readme.md')}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerMarkInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });

  describe('when parsing HTML', () => {
    it('ignores titles for links with "gfm" class in it', () => {
      const expectedDoc = doc(
        p(link({ href: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1' }, 'test')),
      );
      tiptapEditor.commands.setContent(GFM_LINK_HTML);

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
