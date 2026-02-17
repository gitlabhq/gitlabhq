import { getFullSource } from '~/content_editor/services/markdown_source';

describe('content_editor/services/markdown_source', () => {
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
});
