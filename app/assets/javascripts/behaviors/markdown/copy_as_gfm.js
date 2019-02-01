import $ from 'jquery';
import { DOMParser } from 'prosemirror-model';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import schema from './schema';
import markdownSerializer from './serializer';

export class CopyAsGFM {
  constructor() {
    // iOS currently does not support clipboardData.setData(). This bug should
    // be fixed in iOS 12, but for now we'll disable this for all iOS browsers
    // ref: https://trac.webkit.org/changeset/222228/webkit
    const userAgent = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
    const isIOS = /\b(iPad|iPhone|iPod)(?=;)/.test(userAgent);
    if (isIOS) return;

    $(document).on('copy', '.md, .wiki', e => {
      CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformGFMSelection);
    });
    $(document).on('copy', 'pre.code.highlight, .diff-content .line_content', e => {
      CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformCodeSelection);
    });
    $(document).on('paste', '.js-gfm-input', CopyAsGFM.pasteGFM);
  }

  static copyAsGFM(e, transformer) {
    const { clipboardData } = e.originalEvent;
    if (!clipboardData) return;

    const documentFragment = getSelectedFragment();
    if (!documentFragment) return;

    const el = transformer(documentFragment.cloneNode(true), e.currentTarget);
    if (!el) return;

    e.preventDefault();
    e.stopPropagation();

    const div = document.createElement('div');
    div.appendChild(el.cloneNode(true));
    const html = div.innerHTML;

    clipboardData.setData('text/plain', el.textContent);
    clipboardData.setData('text/x-gfm', this.nodeToGFM(el));
    clipboardData.setData('text/html', html);
  }

  static pasteGFM(e) {
    const { clipboardData } = e.originalEvent;
    if (!clipboardData) return;

    const text = clipboardData.getData('text/plain');
    const gfm = clipboardData.getData('text/x-gfm');
    if (!gfm) return;

    e.preventDefault();

    window.gl.utils.insertText(e.target, textBefore => {
      // If the text before the cursor contains an odd number of backticks,
      // we are either inside an inline code span that starts with 1 backtick
      // or a code block that starts with 3 backticks.
      // This logic still holds when there are one or more _closed_ code spans
      // or blocks that will have 2 or 6 backticks.
      // This will break down when the actual code block contains an uneven
      // number of backticks, but this is a rare edge case.
      const backtickMatch = textBefore.match(/`/g);
      const insideCodeBlock = backtickMatch && backtickMatch.length % 2 === 1;

      if (insideCodeBlock) {
        return text;
      }

      return gfm;
    });
  }

  static transformGFMSelection(documentFragment) {
    const gfmElements = documentFragment.querySelectorAll('.md, .wiki');
    switch (gfmElements.length) {
      case 0: {
        return documentFragment;
      }
      case 1: {
        return gfmElements[0];
      }
      default: {
        const allGfmElement = document.createElement('div');

        for (let i = 0; i < gfmElements.length; i += 1) {
          const gfmElement = gfmElements[i];
          allGfmElement.appendChild(gfmElement);
          allGfmElement.appendChild(document.createTextNode('\n\n'));
        }

        return allGfmElement;
      }
    }
  }

  static transformCodeSelection(documentFragment, target) {
    let lineSelector = '.line';

    if (target) {
      const lineClass = ['left-side', 'right-side'].filter(name =>
        target.classList.contains(name),
      )[0];
      if (lineClass) {
        lineSelector = `.line_content.${lineClass} ${lineSelector}`;
      }
    }

    const lineElements = documentFragment.querySelectorAll(lineSelector);

    let codeElement;
    if (lineElements.length > 1) {
      codeElement = document.createElement('pre');
      codeElement.className = 'code highlight';

      const lang = lineElements[0].getAttribute('lang');
      if (lang) {
        codeElement.setAttribute('lang', lang);
      }
    } else {
      codeElement = document.createElement('code');
    }

    if (lineElements.length > 0) {
      for (let i = 0; i < lineElements.length; i += 1) {
        const lineElement = lineElements[i];
        codeElement.appendChild(lineElement);
        codeElement.appendChild(document.createTextNode('\n'));
      }
    } else {
      codeElement.appendChild(documentFragment);
    }

    return codeElement;
  }

  static nodeToGFM(node) {
    const wrapEl = document.createElement('div');
    wrapEl.appendChild(node.cloneNode(true));
    const doc = DOMParser.fromSchema(schema).parse(wrapEl);

    return markdownSerializer.serialize(doc);
  }
}

// Export CopyAsGFM as a global for rspec to access
// see /spec/features/copy_as_gfm_spec.rb
if (process.env.NODE_ENV !== 'production') {
  window.CopyAsGFM = CopyAsGFM;
}

export default function initCopyAsGFM() {
  return new CopyAsGFM();
}
