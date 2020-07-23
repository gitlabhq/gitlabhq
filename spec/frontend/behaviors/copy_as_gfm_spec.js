import * as commonUtils from '~/lib/utils/common_utils';
import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';

describe('CopyAsGFM', () => {
  describe('CopyAsGFM.pasteGFM', () => {
    function callPasteGFM() {
      const e = {
        originalEvent: {
          clipboardData: {
            getData(mimeType) {
              // When GFM code is copied, we put the regular plain text
              // on the clipboard as `text/plain`, and the GFM as `text/x-gfm`.
              // This emulates the behavior of `getData` with that data.
              if (mimeType === 'text/plain') {
                return 'code';
              }
              if (mimeType === 'text/x-gfm') {
                return '`code`';
              }
              return null;
            },
          },
        },
        preventDefault() {},
      };

      CopyAsGFM.pasteGFM(e);
    }

    it('wraps pasted code when not already in code tags', () => {
      jest.spyOn(commonUtils, 'insertText').mockImplementation((el, textFunc) => {
        const insertedText = textFunc('This is code: ', '');

        expect(insertedText).toEqual('`code`');
      });

      callPasteGFM();
    });

    it('does not wrap pasted code when already in code tags', () => {
      jest.spyOn(commonUtils, 'insertText').mockImplementation((el, textFunc) => {
        const insertedText = textFunc('This is code: `', '`');

        expect(insertedText).toEqual('code');
      });

      callPasteGFM();
    });
  });

  describe('CopyAsGFM.copyGFM', () => {
    // Stub getSelection to return a purpose-built object.
    const stubSelection = (html, parentNode) => ({
      getRangeAt: () => ({
        commonAncestorContainer: { tagName: parentNode },
        cloneContents: () => {
          const fragment = document.createDocumentFragment();
          const node = document.createElement('div');
          node.innerHTML = html;
          Array.from(node.childNodes).forEach(item => fragment.appendChild(item));
          return fragment;
        },
      }),
      rangeCount: 1,
    });

    const clipboardData = {
      setData() {},
    };

    const simulateCopy = () => {
      const e = {
        originalEvent: {
          clipboardData,
        },
        preventDefault() {},
        stopPropagation() {},
      };
      CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformGFMSelection);
      return clipboardData;
    };

    beforeAll(done => {
      initCopyAsGFM();

      // Fake call to nodeToGfm so the import of lazy bundle happened
      CopyAsGFM.nodeToGFM(document.createElement('div'))
        .then(() => {
          done();
        })
        .catch(done.fail);
    });

    beforeEach(() => jest.spyOn(clipboardData, 'setData'));

    describe('list handling', () => {
      it('uses correct gfm for unordered lists', done => {
        const selection = stubSelection('<li>List Item1</li><li>List Item2</li>\n', 'UL');

        window.getSelection = jest.fn(() => selection);
        simulateCopy();

        setImmediate(() => {
          const expectedGFM = '* List Item1\n* List Item2';

          expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', expectedGFM);
          done();
        });
      });

      it('uses correct gfm for ordered lists', done => {
        const selection = stubSelection('<li>List Item1</li><li>List Item2</li>\n', 'OL');

        window.getSelection = jest.fn(() => selection);
        simulateCopy();

        setImmediate(() => {
          const expectedGFM = '1. List Item1\n1. List Item2';

          expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', expectedGFM);
          done();
        });
      });
    });
  });

  describe('CopyAsGFM.quoted', () => {
    const sampleGFM = '* List 1\n* List 2\n\n`Some code`';

    it('adds quote char `> ` to each line', done => {
      const expectedQuotedGFM = '> * List 1\n> * List 2\n> \n> `Some code`';
      expect(CopyAsGFM.quoted(sampleGFM)).toEqual(expectedQuotedGFM);
      done();
    });
  });
});
