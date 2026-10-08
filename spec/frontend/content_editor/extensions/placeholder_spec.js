import { builders } from 'prosemirror-test-builder';
import Placeholder from '~/content_editor/extensions/placeholder';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/placeholder', () => {
  let tiptapEditor;
  let doc;
  let p;
  let placeholder;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Placeholder] });

    ({ doc, paragraph: p, placeholder } = builders(tiptapEditor.schema));
  });

  describe('when parsing HTML', () => {
    describe('when the placeholder was resolved', () => {
      it('parses the value as the text and the syntax from the data attribute', () => {
        tiptapEditor.commands.setContent(
          '<p>in <span data-placeholder="%{project_name}">gitlab</span> we trust</p>',
        );

        expect(tiptapEditor.getJSON()).toEqual(
          doc(
            p('in ', placeholder({ placeholder: '%{project_name}', value: 'gitlab' }), ' we trust'),
          ).toJSON(),
        );
      });
    });

    describe('when the placeholder resolved to an empty value', () => {
      it('leaves the value null', () => {
        tiptapEditor.commands.setContent('<p><span data-placeholder="%{current_ref}"></span></p>');

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p(placeholder({ placeholder: '%{current_ref}', value: null }))).toJSON(),
        );
      });
    });

    describe('when the placeholder was not resolved', () => {
      it('takes the syntax from the text', () => {
        tiptapEditor.commands.setContent('<p><span data-placeholder>%{foo}</span></p>');

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p(placeholder({ placeholder: '%{foo}', value: null }))).toJSON(),
        );
      });
    });

    describe('when the placeholder name contains non-ASCII word characters', () => {
      it('parses the placeholder', () => {
        tiptapEditor.commands.setContent('<p><span data-placeholder>%{héllo_wörld}</span></p>');

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p(placeholder({ placeholder: '%{héllo_wörld}', value: null }))).toJSON(),
        );
      });
    });

    describe('when the span is not a placeholder', () => {
      it.each`
        description                                       | html                                                                         | text
        ${'the data attribute is not placeholder syntax'} | ${'<p><span data-placeholder="/label ~bug">hello</span></p>'}                | ${'hello'}
        ${'the data attribute contains a newline'}        | ${'<p><span data-placeholder="%{foo}&#10;/close">hello</span></p>'}          | ${'hello'}
        ${'the text is not placeholder syntax'}           | ${'<p><span data-placeholder>hello</span></p>'}                              | ${'hello'}
        ${'the placeholder name is too long'}             | ${'<p><span data-placeholder>%{aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa}</span></p>'} | ${'%{aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa}'}
        ${'the span contains an element'}                 | ${'<p><span data-placeholder="%{foo}"><em>hello</em></span></p>'}            | ${'hello'}
        ${'the placeholder syntax is inside an element'}  | ${'<p><span data-placeholder><em>%{foo}</em></span></p>'}                    | ${'%{foo}'}
        ${'the span and its data attribute are empty'}    | ${'<p><span data-placeholder></span>hello</p>'}                              | ${'hello'}
      `('does not parse a placeholder when $description', ({ html, text }) => {
        tiptapEditor.commands.setContent(html);

        expect(tiptapEditor.getJSON()).toEqual(doc(p(text)).toJSON());
      });
    });
  });

  describe('when rendering HTML', () => {
    it.each`
      attrs                                                  | html
      ${{ placeholder: '%{project_name}', value: 'gitlab' }} | ${'<span data-placeholder="%{project_name}">gitlab</span>'}
      ${{ placeholder: '%{foo}', value: null }}              | ${'<span data-placeholder="">%{foo}</span>'}
    `('renders $attrs as $html', ({ attrs, html }) => {
      tiptapEditor.commands.setContent(doc(p(placeholder(attrs))).toJSON());

      expect(tiptapEditor.getHTML()).toBe(`<p dir="auto">${html}</p>`);
    });

    it('parses its own rendered element back to the same node', () => {
      const initialDoc = doc(
        p(
          placeholder({ placeholder: '%{project_name}', value: 'gitlab' }),
          placeholder({ placeholder: '%{foo}', value: null }),
        ),
      );
      tiptapEditor.commands.setContent(initialDoc.toJSON());

      tiptapEditor.commands.setContent(tiptapEditor.getHTML());

      expect(tiptapEditor.getJSON()).toEqual(initialDoc.toJSON());
    });
  });
});
