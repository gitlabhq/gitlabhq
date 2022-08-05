import Heading from '~/content_editor/extensions/heading';
import { toTree, getHeadings } from '~/content_editor/services/table_of_contents_utils';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/table_of_content_utils', () => {
  describe('toTree', () => {
    it('should fills in gaps in heading levels and convert headings to a tree', () => {
      expect(
        toTree([
          { level: 3, text: '3' },
          { level: 2, text: '2' },
        ]),
      ).toEqual([
        expect.objectContaining({
          level: 1,
          text: '',
          subHeadings: [
            expect.objectContaining({
              level: 2,
              text: '',
              subHeadings: [expect.objectContaining({ level: 3, text: '3', subHeadings: [] })],
            }),
            expect.objectContaining({ level: 2, text: '2', subHeadings: [] }),
          ],
        }),
      ]);
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
        expect.objectContaining({
          level: 1,
          text: 'Heading 1',
          subHeadings: [
            expect.objectContaining({
              level: 2,
              text: 'Heading 1.1',
              subHeadings: [
                expect.objectContaining({ level: 3, text: 'Heading 1.1.1', subHeadings: [] }),
              ],
            }),
            expect.objectContaining({
              level: 2,
              text: 'Heading 1.2',
              subHeadings: [
                expect.objectContaining({ level: 3, text: 'Heading 1.2.1', subHeadings: [] }),
              ],
            }),
            expect.objectContaining({ level: 2, text: 'Heading 1.3', subHeadings: [] }),
            expect.objectContaining({
              level: 2,
              text: 'Heading 1.4',
              subHeadings: [
                expect.objectContaining({ level: 3, text: 'Heading 1.4.1', subHeadings: [] }),
              ],
            }),
          ],
        }),
        expect.objectContaining({
          level: 1,
          text: 'Heading 2',
          subHeadings: [],
        }),
      ]);
    });
  });
});
