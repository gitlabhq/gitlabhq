import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import * as commonUtils from '~/lib/utils/common_utils';

jest.mock('~/emoji');

describe('CopyAsGFM', () => {
  const createFragment = (html) => document.createRange().createContextualFragment(html);

  beforeAll(() => {
    initCopyAsGFM();

    // Fake call to nodeToGfm so the import of lazy bundle happened
    return CopyAsGFM.nodeToGFM(document.createElement('div'));
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('copies .duo-chat-message content as markdown', () => {
    setHTMLFixture('<div class="duo-chat-message"></div>');

    const el = document.querySelector('.duo-chat-message');
    const copyAsGFMSpy = jest.spyOn(CopyAsGFM, 'copyAsGFM');
    const event = new Event('copy', { bubbles: true, cancelable: true });

    el.dispatchEvent(event);

    expect(copyAsGFMSpy).toHaveBeenCalled();
  });

  describe('CopyAsGFM.pasteGFM', () => {
    let target;

    beforeEach(() => {
      target = document.createElement('input');
      target.value = 'This is code: ';

      // needed for the underlying insertText to work
      document.execCommand = jest.fn(() => false);
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

      return waitForPromises();
    };

    beforeEach(() => jest.spyOn(clipboardData, 'setData'));

    describe('list handling', () => {
      it('uses correct gfm for unordered lists', async () => {
        const selection = stubSelection('<li>List Item1</li><li>List Item2</li>\n', 'UL');

        window.getSelection = jest.fn(() => selection);
        await simulateCopy();

        const expectedGFM = '* List Item1\n* List Item2';

        expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', expectedGFM);
      });

      it('uses correct gfm for ordered lists', async () => {
        const selection = stubSelection('<li>List Item1</li><li>List Item2</li>\n', 'OL');

        window.getSelection = jest.fn(() => selection);
        await simulateCopy();

        const expectedGFM = '1. List Item1\n2. List Item2';

        expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', expectedGFM);
      });
    });
  });

  describe('CopyAsGFM.quoted', () => {
    const sampleGFM = '* List 1\n* List 2\n\n`Some code`';

    it('adds quote char `> ` to each line', () => {
      const expectedQuotedGFM = '> * List 1\n> * List 2\n> \n> `Some code`';
      expect(CopyAsGFM.quoted(sampleGFM)).toEqual(expectedQuotedGFM);
    });
  });

  describe('isGfmFragment', () => {
    it('returns false for non .md contents', () => {
      const fragment = createFragment('<div></div>');
      expect(CopyAsGFM.isGfmFragment(fragment)).toBe(false);
    });

    it('returns true for .md contents', () => {
      const fragment = createFragment('<div><div></div><div class="md"></div></div>');
      expect(CopyAsGFM.isGfmFragment(fragment)).toBe(true);
    });

    it('returns true for contents inside .md', () => {
      const parent = createFragment('<div class="md"></div>');
      const fragment = createFragment('<div></div>');
      parent.querySelector('.md').replaceChildren(fragment);
      // mimic the result of getSelectedFragment
      fragment.originalNodes = [...parent.children];
      expect(CopyAsGFM.isGfmFragment(fragment)).toBe(true);
    });
  });

  describe('selectionToGfm', () => {
    it('returns empty string for empty selection', async () => {
      jest.spyOn(commonUtils, 'getSelectedFragment').mockReturnValueOnce(null);
      expect(await CopyAsGFM.selectionToGfm()).toBe('');
    });

    it('returns empty string for non md selection', async () => {
      jest
        .spyOn(commonUtils, 'getSelectedFragment')
        .mockReturnValueOnce(createFragment('<div></div>'));
      expect(await CopyAsGFM.selectionToGfm()).toBe('');
    });

    it('returns transformed selection', async () => {
      jest
        .spyOn(commonUtils, 'getSelectedFragment')
        .mockReturnValueOnce(createFragment('<div class="md"></div>'));
      const transformSpy = jest.spyOn(CopyAsGFM, 'transformGFMSelection');
      jest.spyOn(CopyAsGFM, 'nodeToGFM').mockImplementationOnce((node) => node.outerHTML);
      expect(await CopyAsGFM.selectionToGfm()).toBe(
        '<blockquote><div class="md"></div></blockquote>',
      );
      expect(transformSpy).toHaveBeenCalled();
    });
  });
});
