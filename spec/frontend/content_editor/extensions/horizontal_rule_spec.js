import { builders } from 'prosemirror-test-builder';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/horizontal_rule', () => {
  let tiptapEditor;
  let doc;
  let p;
  let horizontalRule;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [HorizontalRule] });

    ({ doc, paragraph: p, horizontalRule } = builders(tiptapEditor.schema));
  });

  it.each`
    input      | insertedNodes
    ${'---'}   | ${() => [horizontalRule(), p()]}
    ${'--'}    | ${() => [p()]}
    ${'---x'}  | ${() => [p()]}
    ${' ---x'} | ${() => [p()]}
    ${' --- '} | ${() => [p()]}
    ${'x---x'} | ${() => [p()]}
    ${'x---'}  | ${() => [p()]}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNodes }) => {
    const expectedDoc = doc(...insertedNodes());

    triggerNodeInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
