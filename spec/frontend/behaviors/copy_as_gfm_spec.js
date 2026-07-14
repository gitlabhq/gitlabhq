import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import * as commonUtils from '~/lib/utils/common_utils';

jest.mock('~/emoji');

describe('CopyAsGFM', () => {
  const createFragment = (html) => document.createRange().createContextualFragment(html);

  // Stub getSelection to return the contents of `node` as the selection,
  // mirroring what the browser produces when the user selects within `node`.
  const stubSelectionFor = (node) => {
    window.getSelection = jest.fn(() => ({
      rangeCount: 1,
      getRangeAt: () => ({
        commonAncestorContainer: node,
        cloneContents: () => {
          const fragment = document.createDocumentFragment();
          Array.from(node.cloneNode(true).childNodes).forEach((child) =>
            fragment.appendChild(child),
          );
          return fragment;
        },
      }),
    }));
  };

  const dispatchClipboardEvent = (type, el, clipboardData) => {
    const event = new Event(type, { bubbles: true, cancelable: true });
    event.clipboardData = clipboardData;
    el.dispatchEvent(event);
    return event;
  };

  beforeAll(() => {
    initCopyAsGFM();

    // Fake call to nodeToGfm so the import of lazy bundle happened
    return CopyAsGFM.nodeToGFM(document.createElement('div'));
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('copies .duo-chat-message content as markdown', async () => {
    setHTMLFixture(
      '<div class="duo-chat-message"><div class="md"><ul><li>List Item1</li><li>List Item2</li></ul></div></div>',
    );

    const el = document.querySelector('.duo-chat-message');
    stubSelectionFor(el);

    const clipboardData = { setData: jest.fn() };
    const event = dispatchClipboardEvent('copy', el, clipboardData);
    await waitForPromises();

    expect(event.defaultPrevented).toBe(true);
    expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', '* List Item1\n* List Item2');
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
        clipboardData: {
          getData(mimeType) {
            return data[mimeType] || null;
          },
        },
        preventDefault() {},
        stopPropagation() {},
        stopImmediatePropagation() {},
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
        clipboardData,
        preventDefault() {},
        stopPropagation() {},
        stopImmediatePropagation() {},
      };
      CopyAsGFM.copyAsGFM(e, null, CopyAsGFM.transformGFMSelection);

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

  describe('clipboard event chain', () => {
    it('copies GFM when a copy event bubbles up from inside a .md element', async () => {
      setHTMLFixture('<div class="md"><ul><li>List Item1</li><li>List Item2</li></ul></div>');

      const leaf = document.querySelector('li');
      stubSelectionFor(document.querySelector('.md'));

      const clipboardData = { setData: jest.fn() };
      const event = dispatchClipboardEvent('copy', leaf, clipboardData);
      await waitForPromises();

      expect(event.defaultPrevented).toBe(true);
      expect(clipboardData.setData).toHaveBeenCalledWith(
        'text/x-gfm',
        '* List Item1\n* List Item2',
      );
    });

    it('copies code when a copy event bubbles up from inside a code line', async () => {
      setHTMLFixture('<pre class="code highlight"><span class="line">code line</span></pre>');

      const leaf = document.querySelector('span.line');
      stubSelectionFor(document.querySelector('pre.code.highlight'));

      const clipboardData = { setData: jest.fn() };
      const event = dispatchClipboardEvent('copy', leaf, clipboardData);
      await waitForPromises();

      expect(event.defaultPrevented).toBe(true);
      expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', '`code line`');
    });

    it('copies code when a copy event bubbles up from inside a Rapid Diffs line', async () => {
      // A diff line cell opts into GFM copy with `data-gfm-source` and carries
      // presentational overlays marked `data-gfm-ignore`. The selector must match
      // the cell so the copy is transformed to GFM; otherwise the browser falls
      // back to a native copy that serializes block-level overlays into extra
      // blank lines.
      setHTMLFixture(
        `<diff-file><table><tbody><tr><td class="rd-line-content" data-change="added" data-gfm-source="true">
          <span class="has-tooltip" data-line-coverage="1" data-gfm-ignore="true"></span>
          <div data-line-codequality="1" data-gfm-ignore="true"></div>
          <pre class="rd-line-text"><span class="line" data-lang="javascript">code line</span></pre>
        </td></tr></tbody></table></diff-file>`,
      );

      const leaf = document.querySelector('span.line');
      stubSelectionFor(document.querySelector('.rd-line-content'));

      const clipboardData = { setData: jest.fn() };
      const event = dispatchClipboardEvent('copy', leaf, clipboardData);
      await waitForPromises();

      expect(event.defaultPrevented).toBe(true);
      expect(clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', '`code line`');
    });

    it('transforms pasted GFM when a paste event fires on a .js-gfm-input', () => {
      setHTMLFixture('<textarea class="js-gfm-input"></textarea>');

      const target = document.querySelector('.js-gfm-input');
      target.value = 'This is code: ';
      document.execCommand = jest.fn(() => false);

      const data = { 'text/plain': 'code', 'text/x-gfm': '`code`' };
      const clipboardData = { getData: (mimeType) => data[mimeType] || null };
      const event = dispatchClipboardEvent('paste', target, clipboardData);

      expect(event.defaultPrevented).toBe(true);
      expect(target.value).toBe('This is code: `code`');
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

  describe('transformCodeSelection', () => {
    it('strips coverage and code quality overlays from a copied Rapid Diffs line', () => {
      // In parallel view the cell carries `data-position`, so the line selector is
      // scoped to that side. A single-line selection clones the cell's children
      // without the `[data-position]` wrapper, so the selector misses and the raw
      // fragment is used verbatim. The `data-gfm-ignore` overlays must still be
      // stripped so a block-level overlay does not serialize to extra blank lines.
      const overlays =
        '<span class="has-tooltip" data-line-coverage="1" data-gfm-ignore="true"></span>' +
        '<div data-line-codequality="1" data-gfm-ignore="true"></div>' +
        '<pre class="rd-line-text"><span class="line">code line</span></pre>';
      setHTMLFixture(
        `<diff-file><table><tbody><tr><td class="rd-line-content" data-position="new" data-gfm-source="true">${overlays}</td></tr></tbody></table></diff-file>`,
      );
      const target = document.querySelector('.rd-line-content');

      const el = CopyAsGFM.transformCodeSelection(createFragment(overlays), target);

      expect(el.querySelector('[data-gfm-ignore]')).toBe(null);
      expect(el.textContent).toContain('code line');
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
