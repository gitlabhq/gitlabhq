import { builders } from 'prosemirror-test-builder';
import Link from '~/content_editor/extensions/link';
import { createTestEditor, triggerMarkInputRule } from '../test_utils';

const GFM_LINK_HTML =
  '<p data-sourcepos="1:1-1:63" dir="auto"><a href="https://gitlab.com/gitlab-org/gitlab-test/-/issues/1" data-reference-type="issue" data-original="test" data-link="true" data-link-reference="true" data-issue="11" data-project="2" data-iid="1" data-namespace-path="gitlab-org/gitlab-test" data-project-path="gitlab-org/gitlab-test" data-issue-type="issue" data-container="body" data-placement="top" title="Rerum vero repellat saepe sunt ullam provident." class="gfm gfm-issue">test</a></p>';

const VALID_CUSTOM_PROTOCOL_LINK_HTML = `
  <a href="slack://open">test1</a>
  <a href="x-devonthink-item://90909">test2</a>
  <a href="x-devonthink-item:90909">test3</a>
  `;

const INVALID_CUSTOM_PROTOCOL_LINK_HTML = `
  <a href="javascript:alert(1)">test1</a> 
  <a href="jAvascript:alert(1)">test2</a> 
  <a href="data:text/html,<script>alert(1);</script>">test3</a> 
  <a href=" javascript:">test4</a> 
  <a href="javascript :">test5</a> 
  `;

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

    it('accepts valid urls with custom protocols', () => {
      const expectedDoc = doc(
        p(
          link({ href: 'slack://open' }, 'test1'),
          link({ href: 'x-devonthink-item://90909' }, 'test2'),
          link({ href: 'x-devonthink-item:90909' }, 'test3'),
        ),
      );
      tiptapEditor.commands.setContent(VALID_CUSTOM_PROTOCOL_LINK_HTML);

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });

    it('ignores invalid urls', () => {
      const expectedDoc = doc(p('test1 test2 test3 test4 test5'));
      tiptapEditor.commands.setContent(INVALID_CUSTOM_PROTOCOL_LINK_HTML);

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
