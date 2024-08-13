import { builders } from 'prosemirror-test-builder';
import Heading from '~/content_editor/extensions/heading';
import {
  toTree,
  getHeadings,
  fillEmpty,
  getHeadingsFromDOM,
} from '~/content_editor/services/table_of_contents_utils';
import { createTestEditor } from '../test_utils';

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

    const { heading, doc } = builders(tiptapEditor.schema);

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

  describe('getHeadingsFromDOM', () => {
    it('gets all headings as a tree in a DOM element', () => {
      const element = document.createElement('div');
      element.innerHTML = `
        <h1><a href="#heading-1"></a>Heading 1</h1>
        <h2><a href="#heading-1-1"></a>Heading 1.1</h2>
        <h3><a href="#heading-1-1-1"></a>Heading 1.1.1</h3>
        <h2><a href="#heading-1-2"></a>Heading 1.2</h2>
        <h3><a href="#heading-1-2-1"></a>Heading 1.2.1</h3>
        <h2><a href="#heading-1-3"></a>Heading 1.3</h2>
        <h2><a href="#heading-1-4"></a>Heading 1.4</h2>
        <h3><a href="#heading-1-4-1"></a>Heading 1.4.1</h3>
        <h1><a href="#heading-2"></a>Heading 2</h1>
      `;

      expect(getHeadingsFromDOM(element)).toEqual([
        {
          href: '#heading-1',
          level: 1,
          subHeadings: [
            {
              href: '#heading-1-1',
              level: 2,
              subHeadings: [
                { href: '#heading-1-1-1', level: 3, subHeadings: [], text: 'Heading 1.1.1' },
              ],
              text: 'Heading 1.1',
            },
            {
              href: '#heading-1-2',
              level: 2,
              subHeadings: [
                { href: '#heading-1-2-1', level: 3, subHeadings: [], text: 'Heading 1.2.1' },
              ],
              text: 'Heading 1.2',
            },
            { href: '#heading-1-3', level: 2, subHeadings: [], text: 'Heading 1.3' },
            {
              href: '#heading-1-4',
              level: 2,
              subHeadings: [
                { href: '#heading-1-4-1', level: 3, subHeadings: [], text: 'Heading 1.4.1' },
              ],
              text: 'Heading 1.4',
            },
          ],
          text: 'Heading 1',
        },
        { href: '#heading-2', level: 1, subHeadings: [], text: 'Heading 2' },
      ]);
    });

    it('returns an empty array if no container element is provided', () => {
      expect(getHeadingsFromDOM(null)).toEqual([]);
    });
  });
});
