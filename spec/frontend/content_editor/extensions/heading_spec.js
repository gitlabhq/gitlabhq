import { builders } from 'prosemirror-test-builder';
import Heading from '~/content_editor/extensions/heading';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/heading', () => {
  let tiptapEditor;
  let doc;
  let p;
  let heading;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Heading] });
    ({ doc, paragraph: p, heading } = builders(tiptapEditor.schema));
  });

  describe('when typing a valid heading input rule', () => {
    it.each`
      level | inputRuleText
      ${1}  | ${'# '}
      ${2}  | ${'## '}
      ${3}  | ${'### '}
      ${4}  | ${'#### '}
      ${5}  | ${'##### '}
      ${6}  | ${'###### '}
    `('inserts a heading node for $inputRuleText', ({ level, inputRuleText }) => {
      const expectedDoc = doc(heading({ level }));

      triggerNodeInputRule({ tiptapEditor, inputRuleText });

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('when typing a invalid heading input rule', () => {
    it.each`
      inputRuleText
      ${'#hi'}
      ${'#\n'}
    `('does not insert a heading node for $inputRuleText', ({ inputRuleText }) => {
      const expectedDoc = doc(p());

      triggerNodeInputRule({ tiptapEditor, inputRuleText });

      // no change to the document
      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
