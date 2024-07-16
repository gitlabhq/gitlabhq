import { builders } from 'prosemirror-test-builder';
import Frontmatter from '~/content_editor/extensions/frontmatter';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/frontmatter', () => {
  let tiptapEditor;
  let doc;
  let frontmatter;
  let codeBlock;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Frontmatter, CodeBlockHighlight] });

    ({ doc, codeBlock, frontmatter } = builders(tiptapEditor.schema));
  });

  it('inherits from code block highlight extension', () => {
    expect(Frontmatter.parent).toBe(CodeBlockHighlight);
  });

  it('does not insert a frontmatter block when executing code block input rule', () => {
    const expectedDoc = doc(codeBlock({ language: 'plaintext' }, ''));
    const inputRuleText = '``` ';

    triggerNodeInputRule({ tiptapEditor, inputRuleText });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });

  it('sets isFrontmatter attribute to true by default', () => {
    expect(Frontmatter.config.addAttributes()).toEqual(
      expect.objectContaining({
        isFrontmatter: { default: true },
      }),
    );
  });

  it.each`
    command                | result                        | resultDesc
    ${'toggleCodeBlock'}   | ${() => doc(codeBlock(''))}   | ${'code block element'}
    ${'setCodeBlock'}      | ${() => doc(codeBlock(''))}   | ${'code block element'}
    ${'setFrontmatter'}    | ${() => doc(frontmatter(''))} | ${'frontmatter element'}
    ${'toggleFrontmatter'} | ${() => doc(frontmatter(''))} | ${'frontmatter element'}
  `('executing $command should generate a document with a $resultDesc', ({ command, result }) => {
    const expectedDoc = result();

    tiptapEditor.commands[command]();

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
