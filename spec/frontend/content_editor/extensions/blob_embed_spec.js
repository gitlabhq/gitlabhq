import { builders } from 'prosemirror-test-builder';
import BlobEmbed from '~/content_editor/extensions/blob_embed';
import { createTestEditor } from '../test_utils';
import { serialize, builders as serializerBuilders } from '../serialization_utils';

const SHA = '0'.repeat(40);
const URL = `http://test.host/group/project/-/blob/${SHA}/dir/file.rb#L3-6`;

const element = (tag, className, contents) => {
  const el = document.createElement(tag);
  el.className = className;

  if (typeof contents === 'string') {
    el.textContent = contents;
  } else {
    el.append(...contents);
  }

  return el;
};

const serverHTML = ({ url = URL, range = 'Lines 3 to 6' } = {}) => {
  const title = element('a', 'blob-embed-title', 'dir/file.rb');
  title.href = url;

  const lineNumber = element('a', 'diff-line-num', '3');
  lineNumber.href = url;

  const code = element('code', '', [element('span', 'line', 'code')]);
  const pre = element('pre', 'code highlight', [code]);

  return element('div', 'blob-embed file-holder', [
    element('div', 'blob-embed-header file-title', [
      title,
      element('span', 'blob-embed-range', range),
    ]),
    element('div', 'blob-embed-body code-syntax-highlight-theme', [
      element('div', 'line-numbers', [lineNumber]),
      element('div', 'blob-content', [pre]),
    ]),
  ]).outerHTML;
};

describe('content_editor/extensions/blob_embed', () => {
  let tiptapEditor;
  let doc;
  let blobEmbed;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [BlobEmbed] });
    ({ doc, blobEmbed } = builders(tiptapEditor.schema));
  });

  describe('when parsing a server-rendered embed', () => {
    it('creates a single node carrying the permalink URL, title and range', () => {
      tiptapEditor.commands.setContent(serverHTML());

      expect(tiptapEditor.getJSON()).toEqual(
        doc(blobEmbed({ url: URL, text: 'dir/file.rb', range: 'Lines 3 to 6' })).toJSON(),
      );
    });

    describe('when the server clamped the range to the length of the file', () => {
      it('takes the rendered range rather than deriving one from the permalink', () => {
        const url = URL.replace('#L3-6', '#L3-600');

        tiptapEditor.commands.setContent(serverHTML({ url }));

        expect(tiptapEditor.getJSON()).toEqual(
          doc(blobEmbed({ url, text: 'dir/file.rb', range: 'Lines 3 to 6' })).toJSON(),
        );
      });
    });
  });

  describe('when rendering a node to HTML', () => {
    it('reproduces the header the server rendered', () => {
      tiptapEditor.commands.setContent(serverHTML());

      const embed = new DOMParser()
        .parseFromString(tiptapEditor.getHTML(), 'text/html')
        .querySelector('div.blob-embed');
      const title = embed.querySelector('a.blob-embed-title');

      expect(title.getAttribute('href')).toBe(URL);
      expect(title.textContent).toBe('dir/file.rb');
      expect(embed.querySelector('.blob-embed-range').textContent).toBe('Lines 3 to 6');
    });
  });

  describe('when serializing an embed', () => {
    it('returns the bare permalink URL so the server can re-expand it', () => {
      expect(serialize(serializerBuilders.blobEmbed({ url: URL }))).toBe(URL);
    });
  });
});
