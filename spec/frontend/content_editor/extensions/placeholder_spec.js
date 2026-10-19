import { builders } from 'prosemirror-test-builder';
import Placeholder from '~/content_editor/extensions/placeholder';
import Bold from '~/content_editor/extensions/bold';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import AssetResolver from '~/content_editor/services/asset_resolver';
import waitForPromises from 'helpers/wait_for_promises';
import { createTestEditor } from '../test_utils';

const RESOLVED_HTML = '<p><span data-placeholder="%{project_name}">gitlab</span></p>';

describe('content_editor/extensions/placeholder', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let code;
  let codeBlock;
  let placeholder;
  let renderMarkdown;
  let respondWith;

  const createEditor = () => {
    const assetResolver = new AssetResolver({ renderMarkdown });

    tiptapEditor = createTestEditor({
      extensions: [Placeholder.configure({ assetResolver }), Bold, Code, CodeBlockHighlight],
    });

    ({ doc, paragraph: p, bold, code, codeBlock, placeholder } = builders(tiptapEditor.schema));
  };

  const resolvedPlaceholder = () =>
    placeholder({ placeholder: '%{project_name}', value: 'gitlab' });

  const type = (text) => {
    const { view } = tiptapEditor;

    [...text].forEach((char) => {
      const { from, to } = view.state.selection;
      const handled = view.someProp('handleTextInput', (f) => f(view, from, to, char));
      if (!handled) view.dispatch(view.state.tr.insertText(char, from, to));
    });
  };

  const setContentAndSelectEnd = (content) => {
    tiptapEditor.commands.setContent(content.toJSON());
    tiptapEditor.commands.setTextSelection(tiptapEditor.state.doc.content.size - 1);
  };

  const respond = async (body) => {
    respondWith({ body });
    await waitForPromises();
  };

  beforeEach(() => {
    window.gon.features = { markdownPlaceholders: true };
    renderMarkdown = jest.fn(
      () =>
        new Promise((resolve) => {
          respondWith = resolve;
        }),
    );

    createEditor();
  });

  describe('when typing placeholder syntax', () => {
    describe('when the server resolves the placeholder', () => {
      beforeEach(async () => {
        type('in %{project_name}');
        await respond(RESOLVED_HTML);
      });

      it('replaces the typed text with a placeholder node', () => {
        expect(tiptapEditor.getJSON()).toEqual(doc(p('in ', resolvedPlaceholder())).toJSON());
      });

      it('renders only the placeholder syntax', () => {
        expect(renderMarkdown).toHaveBeenCalledWith('%{project_name}');
      });
    });

    describe('when the server leaves the placeholder unresolved', () => {
      it('replaces the typed text with a placeholder node without a value', async () => {
        type('%{foo}');
        await respond('<p><span data-placeholder>%{foo}</span></p>');

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p(placeholder({ placeholder: '%{foo}', value: null }))).toJSON(),
        );
      });
    });

    describe('when the server does not detect a placeholder', () => {
      it('leaves the typed text alone', async () => {
        type('%{foo}');
        await respond('<p>%{foo}</p>');

        expect(tiptapEditor.getJSON()).toEqual(doc(p('%{foo}')).toJSON());
      });
    });

    describe('when the placeholder name contains non-ASCII word characters', () => {
      it('resolves the placeholder', () => {
        type('%{héllo_wörld}');

        expect(renderMarkdown).toHaveBeenCalledWith('%{héllo_wörld}');
      });
    });

    describe('when the text does not match placeholder syntax', () => {
      it.each(['%{}', '%{foo bar}', '{foo}', `%{${'a'.repeat(31)}}`])(
        'does not resolve %s',
        (text) => {
          type(text);

          expect(renderMarkdown).not.toHaveBeenCalled();
        },
      );
    });

    describe('when typed inside inline code', () => {
      it('does not resolve', () => {
        setContentAndSelectEnd(doc(p(code('%{foo'))));
        type('}');

        expect(renderMarkdown).not.toHaveBeenCalled();
      });
    });

    describe('when typed inside a mark', () => {
      it('keeps the mark on the placeholder node', async () => {
        setContentAndSelectEnd(doc(p(bold('in '))));
        type('%{project_name}');
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(doc(p(bold('in ', resolvedPlaceholder()))).toJSON());
      });
    });

    describe('when the same text appears earlier in a code block', () => {
      it('replaces only the typed text', async () => {
        setContentAndSelectEnd(doc(codeBlock('%{project_name}'), p('in ')));
        type('%{project_name}');
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(
          doc(codeBlock('%{project_name}'), p('in ', resolvedPlaceholder())).toJSON(),
        );
      });
    });

    describe('when the same text appears earlier as plain text', () => {
      it('replaces only the typed text', async () => {
        setContentAndSelectEnd(doc(p('%{project_name}'), p('in ')));
        type('%{project_name}');
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p('%{project_name}'), p('in ', resolvedPlaceholder())).toJSON(),
        );
      });
    });

    describe('when typing continues before the server responds', () => {
      it('replaces the typed text', async () => {
        type('in %{project_name}');
        type(' now');
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(
          doc(p('in ', resolvedPlaceholder(), ' now')).toJSON(),
        );
      });
    });

    describe('when text is inserted before it before the server responds', () => {
      it('replaces the typed text at its new position', async () => {
        type('in %{project_name}');
        tiptapEditor.commands.insertContentAt(1, 'well, ');
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(doc(p('well, in ', resolvedPlaceholder())).toJSON());
      });
    });

    describe('when the typed text is changed before the server responds', () => {
      it('leaves the text alone', async () => {
        type('in %{project_name}');
        const { size } = tiptapEditor.state.doc.content;
        tiptapEditor.commands.deleteRange({ from: size - 2, to: size - 1 });
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(doc(p('in %{project_name')).toJSON());
      });
    });

    describe('when the paragraph becomes a code block before the server responds', () => {
      it('leaves the text alone', async () => {
        type('in %{project_name}');
        tiptapEditor.commands.setCodeBlock();
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(doc(codeBlock('in %{project_name}')).toJSON());
      });
    });

    describe('when the typed text becomes inline code before the server responds', () => {
      it.each`
        description           | from  | expected
        ${'all of the text'}  | ${4}  | ${() => p('in ', code('%{project_name}'))}
        ${'part of the text'} | ${13} | ${() => p('in %{project', code('_name}'))}
      `('leaves $description alone', async ({ from, expected }) => {
        type('in %{project_name}');
        const { size } = tiptapEditor.state.doc.content;
        tiptapEditor
          .chain()
          .setTextSelection({ from, to: size - 1 })
          .setMark('code')
          .run();
        await respond(RESOLVED_HTML);

        expect(tiptapEditor.getJSON()).toEqual(doc(expected()).toJSON());
      });
    });

    describe('when the feature flag is disabled', () => {
      beforeEach(() => {
        window.gon.features = { markdownPlaceholders: false };
        createEditor();
      });

      it('does not resolve', () => {
        type('%{project_name}');

        expect(renderMarkdown).not.toHaveBeenCalled();
      });
    });
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
