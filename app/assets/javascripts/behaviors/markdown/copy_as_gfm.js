import $ from 'jquery';
import { sanitize } from '~/lib/dompurify';
import { getSelectedFragment, insertText } from '~/lib/utils/common_utils';

export class CopyAsGFM {
  constructor() {
    // iOS currently does not support clipboardData.setData(). This bug should
    // be fixed in iOS 12, but for now we'll disable this for all iOS browsers
    // ref: https://trac.webkit.org/changeset/222228/webkit
    const userAgent = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
    const isIOS = /\b(iPad|iPhone|iPod)(?=;)/.test(userAgent);
    if (isIOS) return;

    $(document).on('copy', '.md, .duo-chat-message', (e) => {
      CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformGFMSelection);
    });
    $(document).on('copy', 'pre.code.highlight, table.code td.line_content', (e) => {
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
    clipboardData.setData('text/html', html);
    // We are also setting this as fallback to transform the selection to gfm on paste
    clipboardData.setData('text/x-gfm-html', html);

    CopyAsGFM.nodeToGFM(el)
      .then((res) => {
        clipboardData.setData('text/x-gfm', res);
      })
      .catch(() => {
        // Not showing the error as Firefox might doesn't allow
        // it or other browsers who have a time limit on the execution
        // of the copy event
      });
  }

  static pasteGFM(e) {
    const { clipboardData } = e.originalEvent;
    if (!clipboardData) return;

    const text = clipboardData.getData('text/plain');
    const gfm = clipboardData.getData('text/x-gfm');
    const gfmHtml = clipboardData.getData('text/x-gfm-html');
    if (!gfm && !gfmHtml) return;

    e.preventDefault();
    if (gon?.features?.markdownPasteUrl) {
      // See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178942#note_2325656736
      e.stopImmediatePropagation();
    }

    // We have the original selection already converted to gfm
    if (gfm) {
      CopyAsGFM.insertPastedText(e.target, text, gfm);
    } else {
      // Due to the async copy call we are not able to produce gfm so we transform the cached HTML
      const div = document.createElement('div');
      div.innerHTML = sanitize(gfmHtml);
      CopyAsGFM.nodeToGFM(div)
        .then((transformedGfm) => {
          CopyAsGFM.insertPastedText(e.target, text, transformedGfm);
        })
        .catch(() => {});
    }
  }

  static insertPastedText(target, text, gfm) {
    insertText(target, (textBefore) => {
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
    const gfmElements = documentFragment.querySelectorAll('.md');
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
      const lineClass = ['left-side', 'right-side'].filter((name) =>
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
        const line = document.createElement('span');
        line.append(...lineElement.childNodes);
        codeElement.appendChild(line);
        codeElement.appendChild(document.createTextNode('\n'));
      }
    } else {
      codeElement.appendChild(documentFragment);
    }

    [...codeElement.querySelectorAll('.idiff')].forEach((el) => el.classList.remove('idiff'));

    return codeElement;
  }

  static nodeToGFM(node) {
    return Promise.all([
      import(/* webpackChunkName: 'gfm_copy_extra' */ '@tiptap/pm/model'),
      import(/* webpackChunkName: 'gfm_copy_extra' */ './schema'),
      import(/* webpackChunkName: 'gfm_copy_extra' */ './serializer'),
    ])
      .then(([prosemirrorModel, schema, markdownSerializer]) => {
        const { DOMParser } = prosemirrorModel;
        const wrapEl = document.createElement('div');
        wrapEl.appendChild(node.cloneNode(true));
        const doc = DOMParser.fromSchema(schema.default).parse(wrapEl);

        return markdownSerializer.default.serialize(
          { doc },
          { useCanonicalSrc: false, skipEmptyNodes: true },
        );
      })
      .catch(() => {});
  }

  static quoted(markdown) {
    return `> ${markdown.split('\n').join('\n> ')}`;
  }

  static isGfmFragment(documentFragment) {
    let foundMessage = Boolean(documentFragment.querySelector('.md'));
    if (documentFragment.originalNodes) {
      documentFragment.originalNodes.forEach((e) => {
        let node = e;
        do {
          // Text nodes don't define the `matches` method
          if (node.matches && node.matches('.md')) {
            foundMessage = true;
          }
          node = node.parentNode;
        } while (node && !foundMessage);
      });
    }
    return foundMessage;
  }

  static selectionToGfm(root = document.querySelector('#content-body')) {
    const documentFragment = getSelectedFragment(root);
    if (!documentFragment || !CopyAsGFM.isGfmFragment(documentFragment)) return Promise.resolve('');
    const el = CopyAsGFM.transformGFMSelection(documentFragment.cloneNode(true));
    const blockquoteEl = document.createElement('blockquote');
    blockquoteEl.appendChild(el);
    return CopyAsGFM.nodeToGFM(blockquoteEl);
  }
}

// Export CopyAsGFM as a global for rspec to access
// see /spec/features/markdown/copy_as_gfm_spec.rb
if (process.env.NODE_ENV !== 'production') {
  window.CopyAsGFM = CopyAsGFM;
}

export default function initCopyAsGFM() {
  return new CopyAsGFM();
}
