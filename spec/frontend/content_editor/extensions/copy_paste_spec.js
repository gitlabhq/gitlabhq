import CopyPaste from '~/content_editor/extensions/copy_paste';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Loading from '~/content_editor/extensions/loading';
import Diagram from '~/content_editor/extensions/diagram';
import Frontmatter from '~/content_editor/extensions/frontmatter';
import Heading from '~/content_editor/extensions/heading';
import Bold from '~/content_editor/extensions/bold';
import BulletList from '~/content_editor/extensions/bullet_list';
import ListItem from '~/content_editor/extensions/list_item';
import Italic from '~/content_editor/extensions/italic';
import { VARIANT_DANGER } from '~/alert';
import eventHubFactory from '~/helpers/event_hub_factory';
import { ALERT_EVENT } from '~/content_editor/constants';
import waitForPromises from 'helpers/wait_for_promises';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import {
  createTestEditor,
  createDocBuilder,
  waitUntilNextDocTransaction,
  sleep,
} from '../test_utils';

const CODE_BLOCK_HTML = '<pre class="js-syntax-highlight" lang="javascript">var a = 2;</pre>';
const CODE_SUGGESTION_HTML =
  '<pre data-lang-params="-0+0" class="js-syntax-highlight language-suggestion" lang="suggestion">Suggested code</pre>';
const DIAGRAM_HTML =
  '<img data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,WzxmcmFtZT5EZWNvcmF0b3IgcGF0dGVybl0=">';
const FRONTMATTER_HTML = '<pre lang="yaml" data-lang-params="frontmatter">key: value</pre>';
const PARAGRAPH_HTML =
  '<p dir="auto">Some text with <strong>bold</strong> and <em>italic</em> text.</p>';

describe('content_editor/extensions/copy_paste', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let italic;
  let loading;
  let heading;
  let codeBlock;
  let bulletList;
  let listItem;
  let renderMarkdown;
  let resolveRenderMarkdownPromise;
  let resolveRenderMarkdownPromiseAndWait;

  let eventHub;
  const defaultData = { 'text/plain': '**bold text**' };

  beforeEach(() => {
    eventHub = eventHubFactory();
    renderMarkdown = jest.fn().mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveRenderMarkdownPromise = resolve;
          resolveRenderMarkdownPromiseAndWait = (data) =>
            waitUntilNextDocTransaction({ tiptapEditor, action: () => resolve(data) });
        }),
    );

    jest.spyOn(eventHub, '$emit');

    tiptapEditor = createTestEditor({
      extensions: [
        Bold,
        Italic,
        Loading,
        CodeBlockHighlight,
        Diagram,
        Frontmatter,
        Heading,
        BulletList,
        ListItem,
        CopyPaste.configure({ renderMarkdown, eventHub, serializer: new MarkdownSerializer() }),
      ],
    });

    ({
      builders: { doc, p, bold, italic, heading, loading, codeBlock, bulletList, listItem },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        bold: { markType: Bold.name },
        italic: { markType: Italic.name },
        loading: { nodeType: Loading.name },
        heading: { nodeType: Heading.name },
        bulletList: { nodeType: BulletList.name },
        listItem: { nodeType: ListItem.name },
        codeBlock: { nodeType: CodeBlockHighlight.name },
      },
    }));
  });

  const buildClipboardEvent = ({ eventName = 'paste', data = {}, types = ['text/plain'] } = {}) => {
    return Object.assign(new Event(eventName), {
      clipboardData: {
        types,
        getData: jest.fn((type) => data[type] || defaultData[type]),
        setData: jest.fn(),
        clearData: jest.fn(),
      },
    });
  };

  const triggerPasteEventHandler = (event) => {
    return new Promise((resolve) => {
      tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
        resolve(eventHandler(tiptapEditor.view, event));
      });
    });
  };

  const triggerPasteEventHandlerAndWaitForTransaction = (event) => {
    return waitUntilNextDocTransaction({
      tiptapEditor,
      action: () => {
        tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
          return eventHandler(tiptapEditor.view, event);
        });
      },
    });
  };

  it.each`
    types                                                | data                                                  | formatDesc
    ${['text/plain']}                                    | ${{}}                                                 | ${'plain text'}
    ${['text/plain', 'text/html']}                       | ${{}}                                                 | ${'html format'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "markdown" }' }} | ${'vscode markdown'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "ruby" }' }}     | ${'vscode snippet'}
  `('handles $formatDesc', async ({ types, data }) => {
    expect(await triggerPasteEventHandler(buildClipboardEvent({ types, data }))).toBe(true);
  });

  it.each`
    nodeType            | html                    | handled  | desc
    ${'codeBlock'}      | ${CODE_BLOCK_HTML}      | ${false} | ${'does not handle'}
    ${'codeSuggestion'} | ${CODE_SUGGESTION_HTML} | ${false} | ${'does not handle'}
    ${'diagram'}        | ${DIAGRAM_HTML}         | ${false} | ${'does not handle'}
    ${'frontmatter'}    | ${FRONTMATTER_HTML}     | ${false} | ${'does not handle'}
    ${'paragraph'}      | ${PARAGRAPH_HTML}       | ${true}  | ${'handles'}
  `('$desc paste if currently a `$nodeType` is in focus', async ({ html, handled }) => {
    tiptapEditor.commands.insertContent(html);

    expect(await triggerPasteEventHandler(buildClipboardEvent())).toBe(handled);
  });

  describe.each`
    eventName | expectedDoc
    ${'cut'}  | ${() => doc(p())}
    ${'copy'} | ${() => doc(p('Some text with ', bold('bold'), ' and ', italic('italic'), ' text.'))}
  `('when $eventName event is triggered', ({ eventName, expectedDoc }) => {
    let event;
    beforeEach(() => {
      event = buildClipboardEvent({ eventName });

      jest.spyOn(event, 'preventDefault');
      jest.spyOn(event, 'stopPropagation');

      tiptapEditor.commands.insertContent(PARAGRAPH_HTML);
      tiptapEditor.commands.selectAll();
      tiptapEditor.view.dispatchEvent(event);
    });

    it('prevents default', () => {
      expect(event.preventDefault).toHaveBeenCalled();
      expect(event.stopPropagation).toHaveBeenCalled();
    });

    it('sets the clipboard data', () => {
      expect(event.clipboardData.setData).toHaveBeenCalledWith(
        'text/plain',
        'Some text with bold and italic text.',
      );
      expect(event.clipboardData.setData).toHaveBeenCalledWith('text/html', PARAGRAPH_HTML);
      expect(event.clipboardData.setData).toHaveBeenCalledWith(
        'text/x-gfm',
        'Some text with **bold** and _italic_ text.',
      );
    });

    it('modifies the document', () => {
      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc().toJSON());
    });
  });

  describe('when pasting raw markdown source', () => {
    it('shows a loading indicator while markdown is being processed', async () => {
      const expectedDoc = doc(p(loading({ id: expect.any(String) })));

      await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
    });

    it('pastes in the correct position if some content is added before the markdown is processed', async () => {
      const expectedDoc = doc(p(bold('some markdown'), 'some content'));
      const resolvedValue = '<strong>some markdown</strong>';

      await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());

      tiptapEditor.commands.insertContent('some content');
      await resolveRenderMarkdownPromiseAndWait(resolvedValue);

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      expect(tiptapEditor.state.selection.from).toEqual(26); // end of the document
    });

    it('does not paste anything if the loading indicator is deleted before the markdown is processed', async () => {
      const expectedDoc = doc(p());

      await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());
      tiptapEditor.chain().selectAll().deleteSelection().run();
      resolveRenderMarkdownPromise('some markdown');

      // wait some time to be sure no transaction happened
      await sleep();
      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
    });

    describe('when rendering markdown succeeds', () => {
      let resolvedValue;

      beforeEach(() => {
        resolvedValue = '<strong>bold text</strong>';
      });

      it('transforms pasted text into a prosemirror node', async () => {
        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });

      describe('when pasting inline content in an existing paragraph', () => {
        it('inserts the inline content next to the existing paragraph content', async () => {
          const expectedDoc = doc(p('Initial text and', bold('bold text')));

          tiptapEditor.commands.setContent('Initial text and ');

          await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });

      describe('when pasting inline content and there is text selected', () => {
        it('inserts the block content after the existing paragraph', async () => {
          const expectedDoc = doc(p('Initial text', bold('bold text')));

          tiptapEditor.commands.setContent('Initial text and ');
          tiptapEditor.commands.setTextSelection({ from: 13, to: 17 });

          await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });

      describe('when pasting block content in an existing paragraph', () => {
        beforeEach(() => {
          resolvedValue = '<h1>Heading</h1><p><strong>bold text</strong></p>';
        });

        it('inserts the block content after the existing paragraph', async () => {
          const expectedDoc = doc(
            p('Initial text and'),
            heading({ level: 1 }, 'Heading'),
            p(bold('bold text')),
          );

          tiptapEditor.commands.setContent('Initial text and ');

          await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });
    });

    describe('when pasting html content', () => {
      it('strips out any stray div, pre, span tags', async () => {
        const resolvedValue =
          '<div><span dir="auto"><strong>bold text</strong></span></div><pre><code>some code</code></pre>';

        const expectedDoc = doc(p(bold('bold text')), p('some code'));

        await triggerPasteEventHandlerAndWaitForTransaction(
          buildClipboardEvent({
            types: ['text/html'],
            data: {
              'text/html':
                '<div><span dir="auto"><strong>bold text</strong></span></div><pre><code>some code</code></pre>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting text/x-gfm', () => {
      it('processes the content as markdown, even if html content exists', async () => {
        const resolvedValue = '<strong>bold text</strong>';
        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandlerAndWaitForTransaction(
          buildClipboardEvent({
            types: ['text/x-gfm', 'text/plain', 'text/html'],
            data: {
              'text/x-gfm': '**bold text**',
              'text/plain': 'irrelevant text',
              'text/html': '<div>some random irrelevant html</div>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting a single code block with lang=markdown', () => {
      it('process the textContent as markdown, ignoring the htmlContent', async () => {
        const resolvedValue = '<ul><li>Cat</li><li>Dog</li><li>Turtle</li></ul>';
        const expectedDoc = doc(
          bulletList(listItem(p('Cat')), listItem(p('Dog')), listItem(p('Turtle'))),
        );

        await triggerPasteEventHandlerAndWaitForTransaction(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': '- Cat\n- Dog\n- Turtle\n',
              'text/html': `<meta charset='utf-8'><pre class="code highlight" lang="markdown"><span id="LC1" class="line" lang="markdown"><span class="p">-</span> Cat</span>\n<span id="LC2" class="line" lang="markdown"><span class="p">-</span> Dog</span>\n<span id="LC3" class="line" lang="markdown"><span class="p">-</span> Turtle</span>\n</pre>`,
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting vscode-editor-data', () => {
      it('pastes the content as a code block', async () => {
        const resolvedValue =
          '<div class="gl-relative markdown-code-block js-markdown-code">&#x000A;<pre data-sourcepos="1:1-3:3" data-canonical-lang="ruby" class="code highlight js-syntax-highlight language-ruby" lang="ruby" v-pre="true"><code><span id="LC1" class="line" lang="ruby"><span class="nb">puts</span> <span class="s2">"Hello World"</span></span></code></pre>&#x000A;<copy-code></copy-code>&#x000A;</div>';

        const expectedDoc = doc(
          codeBlock(
            { language: 'ruby', class: 'code highlight js-syntax-highlight language-ruby' },
            'puts "Hello World"',
          ),
        );

        await triggerPasteEventHandlerAndWaitForTransaction(
          buildClipboardEvent({
            types: ['vscode-editor-data', 'text/plain', 'text/html'],
            data: {
              'vscode-editor-data': '{ "version": 1, "mode": "ruby" }',
              'text/plain': 'puts "Hello World"',
              'text/html':
                '<meta charset=\'utf-8\'><div style="color: #d4d4d4;background-color: #1e1e1e;font-family: \'Fira Code\', Menlo, Monaco, \'Courier New\', monospace, Menlo, Monaco, \'Courier New\', monospace;font-weight: normal;font-size: 14px;line-height: 21px;white-space: pre;"><div><span style="color: #dcdcaa;">puts</span><span style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Hello world"</span></div></div>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });

      it('pastes as regular markdown if language is markdown', async () => {
        const resolvedValue = '<p><strong>bold text</strong></p>';

        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandlerAndWaitForTransaction(
          buildClipboardEvent({
            types: ['vscode-editor-data', 'text/plain', 'text/html'],
            data: {
              'vscode-editor-data': '{ "version": 1, "mode": "markdown" }',
              'text/plain': '**bold text**',
              'text/html': '<p><strong>bold text</strong></p>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when rendering markdown fails', () => {
      beforeEach(() => {
        renderMarkdown.mockRejectedValueOnce();
      });

      it(`triggers ${ALERT_EVENT} event`, async () => {
        await triggerPasteEventHandler(buildClipboardEvent());
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(ALERT_EVENT, {
          message: expect.any(String),
          variant: VARIANT_DANGER,
        });
      });
    });
  });
});
