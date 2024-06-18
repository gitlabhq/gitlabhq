import Heading from '~/content_editor/extensions/heading';
import { toTree, getHeadings, fillEmpty } from '~/content_editor/services/table_of_contents_utils';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/table_of_content_utils', () => {
  const headings = [
    { level: 3, text: 'Heading 3' },
    { level: 4, text: 'Heading 4' },
    { level: 2, text: 'Heading 2' },
    { level: 1, text: 'Heading 1' },
    { level: 4, text: 'Heading 4' },
    { level: 3, text: 'Heading 3' },
    { level: 2, text: 'Heading 2' },
    { level: 1, text: 'Heading 1' },
    { level: 6, text: 'Heading 6' },
    { level: 3, text: 'Heading 3' },
    { level: 5, text: 'Heading 5' },
    { level: 1, text: 'Heading 1' },
  ];

  describe('fillEmpty', () => {
    it('fills in gaps in heading levels', () => {
      expect(fillEmpty(headings)).toEqual([
        { level: 1, text: '' },
        { level: 2, text: '' },
        { level: 3, text: 'Heading 3' },
        { level: 4, text: 'Heading 4' },
        { level: 2, text: 'Heading 2' },
        { level: 1, text: 'Heading 1' },
        { level: 2, text: '' },
        { level: 3, text: '' },
        { level: 4, text: 'Heading 4' },
        { level: 3, text: 'Heading 3' },
        { level: 2, text: 'Heading 2' },
        { level: 1, text: 'Heading 1' },
        { level: 2, text: '' },
        { level: 3, text: '' },
        { level: 4, text: '' },
        { level: 5, text: '' },
        { level: 6, text: 'Heading 6' },
        { level: 3, text: 'Heading 3' },
        { level: 4, text: '' },
        { level: 5, text: 'Heading 5' },
        { level: 1, text: 'Heading 1' },
      ]);
    });
  });

  describe('toTree', () => {
    it('normalizes missing heading levels and returns a tree', () => {
      expect(toTree(headings)).toEqual({
        level: 0,
        subHeadings: [
          {
            text: 'Heading 3',
            level: 1,
            subHeadings: [{ text: 'Heading 4', level: 2, subHeadings: [] }],
          },
          { text: 'Heading 2', level: 1, subHeadings: [] },
          {
            text: 'Heading 1',
            level: 1,
            subHeadings: [
              { text: 'Heading 4', level: 2, subHeadings: [] },
              { text: 'Heading 3', level: 2, subHeadings: [] },
              { text: 'Heading 2', level: 2, subHeadings: [] },
            ],
          },
          {
            text: 'Heading 1',
            level: 1,
            subHeadings: [
              { text: 'Heading 6', level: 2, subHeadings: [] },
              {
                text: 'Heading 3',
                level: 2,
                subHeadings: [{ text: 'Heading 5', level: 3, subHeadings: [] }],
              },
            ],
          },
          { text: 'Heading 1', level: 1, subHeadings: [] },
        ],
      });
    });
  });

  describe('getHeadings', () => {
    const tiptapEditor = createTestEditor({
      extensions: [Heading],
    });

    const {
      builders: { heading, doc },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        heading: { nodeType: Heading.name },
      },
    });

    it('gets all headings as a tree in a tiptap document', () => {
      const initialDoc = doc(
        heading({ level: 1 }, 'Heading 1'),
        heading({ level: 2 }, 'Heading 1.1'),
        heading({ level: 3 }, 'Heading 1.1.1'),
        heading({ level: 2 }, 'Heading 1.2'),
        heading({ level: 3 }, 'Heading 1.2.1'),
        heading({ level: 2 }, 'Heading 1.3'),
        heading({ level: 2 }, 'Heading 1.4'),
        heading({ level: 3 }, 'Heading 1.4.1'),
        heading({ level: 1 }, 'Heading 2'),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      expect(getHeadings(tiptapEditor)).toEqual([
        {
          level: 1,
          text: 'Heading 1',
          subHeadings: [
            {
              level: 2,
              text: 'Heading 1.1',
              subHeadings: [{ level: 3, text: 'Heading 1.1.1', subHeadings: [] }],
            },
            {
              level: 2,
              text: 'Heading 1.2',
              subHeadings: [{ level: 3, text: 'Heading 1.2.1', subHeadings: [] }],
            },
            { level: 2, text: 'Heading 1.3', subHeadings: [] },
            {
              level: 2,
              text: 'Heading 1.4',
              subHeadings: [{ level: 3, text: 'Heading 1.4.1', subHeadings: [] }],
            },
          ],
        },
        {
          level: 1,
          text: 'Heading 2',
          subHeadings: [],
        },
      ]);
    });
  });
});
