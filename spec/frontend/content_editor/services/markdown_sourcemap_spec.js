import { Extension } from '@tiptap/core';
import BulletList from '~/content_editor/extensions/bullet_list';
import ListItem from '~/content_editor/extensions/list_item';
import Paragraph from '~/content_editor/extensions/paragraph';
import markdownSerializer from '~/content_editor/services/markdown_serializer';
import { getMarkdownSource } from '~/content_editor/services/markdown_sourcemap';
import { loadMarkdownApiResult, loadMarkdownApiExample } from '../markdown_processing_examples';
import { createTestEditor, createDocBuilder } from '../test_utils';

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
              if (source) return { source };
              return {};
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
  it('gets markdown source for a rendered HTML element', async () => {
    const deserialized = await markdownSerializer({
      render: () => loadMarkdownApiResult('bullet_list_style_3'),
      serializerConfig: {},
    }).deserialize({
      schema: tiptapEditor.schema,
      content: loadMarkdownApiExample('bullet_list_style_3'),
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

    expect(deserialized).toEqual(expected.toJSON());
  });
});
