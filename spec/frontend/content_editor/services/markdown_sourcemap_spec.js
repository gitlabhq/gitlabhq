import { Extension } from '@tiptap/core';
import BulletList from '~/content_editor/extensions/bullet_list';
import ListItem from '~/content_editor/extensions/list_item';
import Paragraph from '~/content_editor/extensions/paragraph';
import markdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import { getMarkdownSource, getFullSource } from '~/content_editor/services/markdown_sourcemap';
import { createTestEditor, createDocBuilder } from '../test_utils';

const BULLET_LIST_MARKDOWN = `+ list item 1
+ list item 2
  - embedded list item 3`;
const BULLET_LIST_HTML = `<ul data-sourcepos="1:1-3:24" dir="auto">
  <li data-sourcepos="1:1-1:13">list item 1</li>
  <li data-sourcepos="2:1-3:24">list item 2
    <ul data-sourcepos="3:3-3:24">
      <li data-sourcepos="3:3-3:24">embedded list item 3</li>
    </ul>
  </li>
</ul>`;

const SourcemapExtension = Extension.create({
  // lets add `source` attribute to every element using `getMarkdownSource`
  addGlobalAttributes() {
    return [
      {
        types: [Paragraph.name, BulletList.name, ListItem.name],
        attributes: {
          source: {
            parseHTML: (element) => {
              const source = getMarkdownSource(element);
              return source;
            },
          },
        },
      },
    ];
  },
});

const tiptapEditor = createTestEditor({
  extensions: [BulletList, ListItem, SourcemapExtension],
});

const {
  builders: { doc, bulletList, listItem, paragraph },
} = createDocBuilder({
  tiptapEditor,
  names: {
    bulletList: { nodeType: BulletList.name },
    listItem: { nodeType: ListItem.name },
  },
});

describe('content_editor/services/markdown_sourcemap', () => {
  describe('getFullSource', () => {
    it.each`
      lastChild                                                                | expected
      ${null}                                                                  | ${[]}
      ${{ nodeName: 'paragraph' }}                                             | ${[]}
      ${{ nodeName: '#comment', textContent: null }}                           | ${[]}
      ${{ nodeName: '#comment', textContent: '+ list item 1\n+ list item 2' }} | ${['+ list item 1', '+ list item 2']}
    `('with lastChild=$lastChild, returns $expected', ({ lastChild, expected }) => {
      const element = {
        ownerDocument: {
          body: {
            lastChild,
          },
        },
      };

      expect(getFullSource(element)).toEqual(expected);
    });
  });

  it('gets markdown source for a rendered HTML element', async () => {
    const { document } = await markdownDeserializer({
      render: () => BULLET_LIST_HTML,
    }).deserialize({
      schema: tiptapEditor.schema,
      markdown: BULLET_LIST_MARKDOWN,
    });

    const expected = doc(
      bulletList(
        { bullet: '+', source: '+ list item 1\n+ list item 2' },
        listItem({ source: '+ list item 1' }, paragraph('list item 1')),
        listItem(
          { source: '+ list item 2' },
          paragraph('list item 2'),
          bulletList(
            { bullet: '-', source: '- embedded list item 3' },
            listItem({ source: '- embedded list item 3' }, paragraph('embedded list item 3')),
          ),
        ),
      ),
    );

    expect(document.toJSON()).toEqual(expected.toJSON());
  });
});
