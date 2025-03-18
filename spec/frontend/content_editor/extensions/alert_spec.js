import { builders } from 'prosemirror-test-builder';
import Alert from '~/content_editor/extensions/alert';
import AlertTitle from '~/content_editor/extensions/alert_title';
import { ALERT_TYPES } from '~/content_editor/constants/alert_types';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/alert', () => {
  let tiptapEditor;
  let doc;
  let p;
  let alert;
  let alertTitle;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Alert, AlertTitle] });

    ({ doc, paragraph: p, alert, alertTitle } = builders(tiptapEditor.schema));
  });

  describe('insertAlert command', () => {
    it('inserts an alert block with default type', () => {
      const initialDoc = doc(p('Text content'));
      const expectedDoc = doc(
        p('Text content'),
        alert({ type: ALERT_TYPES.NOTE }, alertTitle(), p()),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.insertAlert();

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe.each(
    Object.values(ALERT_TYPES).map((type) => {
      return {
        type,
        title: `This is a ${type}!`,
        html: `<div class="markdown-alert markdown-alert-${type}"><p class="markdown-alert-title">This is a ${type}!</p><p>some content</p></div>`,
      };
    }),
  )('when parsing alert html with a title', ({ type, html, title }) => {
    beforeEach(() => {
      tiptapEditor.commands.setContent(html);
    });

    it('parses HTML correctly into an alert div with correct type', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(alert({ type }, alertTitle(title), p('some content'))).toJSON(),
      );
    });
  });
});
