import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';

describe('CopyAsGFM', () => {
  describe('CopyAsGFM.pasteGFM', () => {
    let target;

    beforeEach(() => {
      target = document.createElement('input');
      target.value = 'This is code: ';
    });

    // When GFM code is copied, we put the regular plain text
    // on the clipboard as `text/plain`, and the GFM as `text/x-gfm`.
    // This emulates the behavior of `getData` with that data.
    function callPasteGFM(data = { 'text/plain': 'code', 'text/x-gfm': '`code`' }) {
      const e = {
        originalEvent: {
          clipboardData: {
            getData(mimeType) {
              return data[mimeType] || null;
            },
          },
        },
        preventDefault() {},
        target,
      };

      CopyAsGFM.pasteGFM(e);
    }

    it('wraps pasted code when not already in code tags', () => {
      callPasteGFM();

      expect(target.value).toBe('This is code: `code`');
    });

    it('does not wrap pasted code when already in code tags', () => {
      target.value = 'This is code: `';

      callPasteGFM();

      expect(target.value).toBe('This is code: `code');
    });

    it('does not allow xss in x-gfm-html', () => {
      const testEl = document.createElement('div');
      jest.spyOn(document, 'createElement').mockReturnValueOnce(testEl);

      callPasteGFM({ 'text/plain': 'code', 'text/x-gfm-html': 'code<img/src/onerror=alert(1)>' });

      expect(testEl.innerHTML).toBe('code<img src="">');
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
          Array.from(node.childNodes).forEach((item) => fragment.appendChild(item));
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

    beforeAll((done) => {
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
      it('uses correct gfm for unordered lists', (done) => {
        const selection = stubSelection('<li>List Item1</li><li>List Item2</li>\n', 'UL');

        window.getSelection = jest.fn(() => selection);
        simulateCopy();

        setImmediate(() => {
          const expectedGFM = '* List Item1\n* List Item2';

          expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', expectedGFM);
          done();
        });
      });

      it('uses correct gfm for ordered lists', (done) => {
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

    it('adds quote char `> ` to each line', (done) => {
      const expectedQuotedGFM = '> * List 1\n> * List 2\n> \n> `Some code`';
      expect(CopyAsGFM.quoted(sampleGFM)).toEqual(expectedQuotedGFM);
      done();
    });
  });
});
