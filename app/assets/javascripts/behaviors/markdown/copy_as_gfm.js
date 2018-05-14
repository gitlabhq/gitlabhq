/* eslint-disable class-methods-use-this, object-shorthand, no-unused-vars, no-use-before-define, no-new, max-len, no-restricted-syntax, guard-for-in, no-continue */

import $ from 'jquery';
import _ from 'underscore';
import { insertText, getSelectedFragment, nodeMatchesSelector } from '~/lib/utils/common_utils';
import { placeholderImage } from '~/lazy_loader';

const gfmRules = {
  // The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb convert
  // GitLab Flavored Markdown (GFM) to HTML.
  // These handlers consequently convert that same HTML to GFM to be copied to the clipboard.
  // Every filter in lib/banzai/pipeline/gfm_pipeline.rb that generates HTML
  // from GFM should have a handler here, in reverse order.
  // The GFM-to-HTML-to-GFM cycle is tested in spec/features/copy_as_gfm_spec.rb.
  InlineDiffFilter: {
    'span.idiff.addition'(el, text) {
      return `{+${text}+}`;
    },
    'span.idiff.deletion'(el, text) {
      return `{-${text}-}`;
    },
  },
  TaskListFilter: {
    'input[type=checkbox].task-list-item-checkbox'(el) {
      return `[${el.checked ? 'x' : ' '}]`;
    },
  },
  ReferenceFilter: {
    '.tooltip'(el) {
      return '';
    },
    'a.gfm:not([data-link=true])'(el, text) {
      return el.dataset.original || text;
    },
  },
  AutolinkFilter: {
    'a'(el, text) {
      // Fallback on the regular MarkdownFilter's `a` handler.
      if (text !== el.getAttribute('href')) return false;

      return text;
    },
  },
  TableOfContentsFilter: {
    'ul.section-nav'(el) {
      return '[[_TOC_]]';
    },
  },
  EmojiFilter: {
    'img.emoji'(el) {
      return el.getAttribute('alt');
    },
    'gl-emoji'(el) {
      return `:${el.getAttribute('data-name')}:`;
    },
  },
  ImageLinkFilter: {
    'a.no-attachment-icon'(el, text) {
      return text;
    },
  },
  ImageLazyLoadFilter: {
    'img'(el, text) {
      return `![${el.getAttribute('alt')}](${el.getAttribute('src')})`;
    },
  },
  VideoLinkFilter: {
    '.video-container'(el) {
      const videoEl = el.querySelector('video');
      if (!videoEl) return false;

      return CopyAsGFM.nodeToGFM(videoEl);
    },
    'video'(el) {
      return `![${el.dataset.title}](${el.getAttribute('src')})`;
    },
  },
  MermaidFilter: {
    'svg.mermaid'(el, text) {
      const sourceEl = el.querySelector('text.source');
      if (!sourceEl) return false;

      return `\`\`\`mermaid\n${CopyAsGFM.nodeToGFM(sourceEl)}\n\`\`\``;
    },
    'svg.mermaid style, svg.mermaid g'(el, text) {
      // We don't want to include the content of these elements in the copied text.
      return '';
    },
  },
  MathFilter: {
    'pre.code.math[data-math-style=display]'(el, text) {
      return `\`\`\`math\n${text.trim()}\n\`\`\``;
    },
    'code.code.math[data-math-style=inline]'(el, text) {
      return `$\`${text}\`$`;
    },
    'span.katex-display span.katex-mathml'(el) {
      const mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
      if (!mathAnnotation) return false;

      return `\`\`\`math\n${CopyAsGFM.nodeToGFM(mathAnnotation)}\n\`\`\``;
    },
    'span.katex-mathml'(el) {
      const mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
      if (!mathAnnotation) return false;

      return `$\`${CopyAsGFM.nodeToGFM(mathAnnotation)}\`$`;
    },
    'span.katex-html'(el) {
      // We don't want to include the content of this element in the copied text.
      return '';
    },
    'annotation[encoding="application/x-tex"]'(el, text) {
      return text.trim();
    },
  },
  SanitizationFilter: {
    'a[name]:not([href]):empty'(el) {
      return el.outerHTML;
    },
    'dl'(el, text) {
      let lines = text.trim().split('\n');
      // Add two spaces to the front of subsequent list items lines,
      // or leave the line entirely blank.
      lines = lines.map((l) => {
        const line = l.trim();
        if (line.length === 0) return '';

        return `  ${line}`;
      });

      return `<dl>\n${lines.join('\n')}\n</dl>`;
    },
    'sub, dt, dd, kbd, q, samp, var, ruby, rt, rp, abbr, summary, details'(el, text) {
      const tag = el.nodeName.toLowerCase();
      return `<${tag}>${text}</${tag}>`;
    },
  },
  SyntaxHighlightFilter: {
    'pre.code.highlight'(el, t) {
      const text = t.trimRight();

      let lang = el.getAttribute('lang');
      if (!lang || lang === 'plaintext') {
        lang = '';
      }

      // Prefixes lines with 4 spaces if the code contains triple backticks
      if (lang === '' && text.match(/^```/gm)) {
        return text.split('\n').map((l) => {
          const line = l.trim();
          if (line.length === 0) return '';

          return `    ${line}`;
        }).join('\n');
      }

      return `\`\`\`${lang}\n${text}\n\`\`\``;
    },
    'pre > code'(el, text) {
       // Don't wrap code blocks in ``
      return text;
    },
  },
  MarkdownFilter: {
    'br'(el) {
      // Two spaces at the end of a line are turned into a BR
      return '  ';
    },
    'code'(el, text) {
      let backtickCount = 1;
      const backtickMatch = text.match(/`+/);
      if (backtickMatch) {
        backtickCount = backtickMatch[0].length + 1;
      }

      const backticks = Array(backtickCount + 1).join('`');
      const spaceOrNoSpace = backtickCount > 1 ? ' ' : '';

      return backticks + spaceOrNoSpace + text.trim() + spaceOrNoSpace + backticks;
    },
    'blockquote'(el, text) {
      return text.trim().split('\n').map(s => `> ${s}`.trim()).join('\n');
    },
    'img'(el) {
      const imageSrc = el.src;
      const imageUrl = imageSrc && imageSrc !== placeholderImage ? imageSrc : (el.dataset.src || '');
      return `![${el.getAttribute('alt')}](${imageUrl})`;
    },
    'a.anchor'(el, text) {
      // Don't render a Markdown link for the anchor link inside a heading
      return text;
    },
    'a'(el, text) {
      return `[${text}](${el.getAttribute('href')})`;
    },
    'li'(el, text) {
      const lines = text.trim().split('\n');
      const firstLine = `- ${lines.shift()}`;
      // Add four spaces to the front of subsequent list items lines,
      // or leave the line entirely blank.
      const nextLines = lines.map((s) => {
        if (s.trim().length === 0) return '';

        return `    ${s}`;
      });

      return `${firstLine}\n${nextLines.join('\n')}`;
    },
    'ul'(el, text) {
      return text;
    },
    'ol'(el, text) {
      // LIs get a `- ` prefix by default, which we replace by `1. ` for ordered lists.
      return text.replace(/^- /mg, '1. ');
    },
    'h1'(el, text) {
      return `# ${text.trim()}`;
    },
    'h2'(el, text) {
      return `## ${text.trim()}`;
    },
    'h3'(el, text) {
      return `### ${text.trim()}`;
    },
    'h4'(el, text) {
      return `#### ${text.trim()}`;
    },
    'h5'(el, text) {
      return `##### ${text.trim()}`;
    },
    'h6'(el, text) {
      return `###### ${text.trim()}`;
    },
    'strong'(el, text) {
      return `**${text}**`;
    },
    'em'(el, text) {
      return `_${text}_`;
    },
    'del'(el, text) {
      return `~~${text}~~`;
    },
    'sup'(el, text) {
      return `^${text}`;
    },
    'hr'(el) {
      return '-----';
    },
    'table'(el) {
      const theadEl = el.querySelector('thead');
      const tbodyEl = el.querySelector('tbody');
      if (!theadEl || !tbodyEl) return false;

      const theadText = CopyAsGFM.nodeToGFM(theadEl);
      const tbodyText = CopyAsGFM.nodeToGFM(tbodyEl);

      return [theadText, tbodyText].join('\n');
    },
    'thead'(el, text) {
      const cells = _.map(el.querySelectorAll('th'), (cell) => {
        let chars = CopyAsGFM.nodeToGFM(cell).length + 2;

        let before = '';
        let after = '';
        switch (cell.style.textAlign) {
          case 'center':
            before = ':';
            after = ':';
            chars -= 2;
            break;
          case 'right':
            after = ':';
            chars -= 1;
            break;
          default:
            break;
        }

        chars = Math.max(chars, 3);

        const middle = Array(chars + 1).join('-');

        return before + middle + after;
      });

      const separatorRow = `|${cells.join('|')}|`;

      return [text, separatorRow].join('\n');
    },
    'tr'(el) {
      const cellEls = el.querySelectorAll('td, th');
      if (cellEls.length === 0) return false;

      const cells = _.map(cellEls, cell => CopyAsGFM.nodeToGFM(cell));
      return `| ${cells.join(' | ')} |`;
    },
  },
};

export class CopyAsGFM {
  constructor() {
    // iOS currently does not support clipboardData.setData(). This bug should
    // be fixed in iOS 12, but for now we'll disable this for all iOS browsers
    // ref: https://trac.webkit.org/changeset/222228/webkit
    const userAgent = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
    const isIOS = /\b(iPad|iPhone|iPod)(?=;)/.test(userAgent);
    if (isIOS) return;

    $(document).on('copy', '.md, .wiki', (e) => { CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformGFMSelection); });
    $(document).on('copy', 'pre.code.highlight, .diff-content .line_content', (e) => { CopyAsGFM.copyAsGFM(e, CopyAsGFM.transformCodeSelection); });
    $(document).on('paste', '.js-gfm-input', CopyAsGFM.pasteGFM);
  }

  static copyAsGFM(e, transformer) {
    const clipboardData = e.originalEvent.clipboardData;
    if (!clipboardData) return;

    const documentFragment = getSelectedFragment();
    if (!documentFragment) return;

    const el = transformer(documentFragment.cloneNode(true), e.currentTarget);
    if (!el) return;

    e.preventDefault();
    e.stopPropagation();

    clipboardData.setData('text/plain', el.textContent);
    clipboardData.setData('text/x-gfm', this.nodeToGFM(el));
  }

  static pasteGFM(e) {
    const clipboardData = e.originalEvent.clipboardData;
    if (!clipboardData) return;

    const text = clipboardData.getData('text/plain');
    const gfm = clipboardData.getData('text/x-gfm');
    if (!gfm) return;

    e.preventDefault();

    window.gl.utils.insertText(e.target, (textBefore, textAfter) => {
      // If the text before the cursor contains an odd number of backticks,
      // we are either inside an inline code span that starts with 1 backtick
      // or a code block that starts with 3 backticks.
      // This logic still holds when there are one or more _closed_ code spans
      // or blocks that will have 2 or 6 backticks.
      // This will break down when the actual code block contains an uneven
      // number of backticks, but this is a rare edge case.
      const backtickMatch = textBefore.match(/`/g);
      const insideCodeBlock = backtickMatch && (backtickMatch.length % 2) === 1;

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
      const lineClass = ['left-side', 'right-side'].filter(name => target.classList.contains(name))[0];
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

  static nodeToGFM(node, respectWhitespaceParam = false) {
    if (node.nodeType === Node.COMMENT_NODE) {
      return '';
    }

    if (node.nodeType === Node.TEXT_NODE) {
      return node.textContent;
    }

    const respectWhitespace = respectWhitespaceParam || (node.nodeName === 'PRE' || node.nodeName === 'CODE');

    const text = this.innerGFM(node, respectWhitespace);

    if (node.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
      return text;
    }

    for (const filter in gfmRules) {
      const rules = gfmRules[filter];

      for (const selector in rules) {
        const func = rules[selector];

        if (!nodeMatchesSelector(node, selector)) continue;

        let result;
        if (func.length === 2) {
          // if `func` takes 2 arguments, it depends on text.
          // if there is no text, we don't need to generate GFM for this node.
          if (text.length === 0) continue;

          result = func(node, text);
        } else {
          result = func(node);
        }

        if (result === false) continue;

        return result;
      }
    }

    return text;
  }

  static innerGFM(parentNode, respectWhitespace = false) {
    const nodes = parentNode.childNodes;

    const clonedParentNode = parentNode.cloneNode(true);
    const clonedNodes = Array.prototype.slice.call(clonedParentNode.childNodes, 0);

    for (let i = 0; i < nodes.length; i += 1) {
      const node = nodes[i];
      const clonedNode = clonedNodes[i];

      const text = this.nodeToGFM(node, respectWhitespace);

      // `clonedNode.replaceWith(text)` is not yet widely supported
      clonedNode.parentNode.replaceChild(document.createTextNode(text), clonedNode);
    }

    let nodeText = clonedParentNode.innerText || clonedParentNode.textContent;

    if (!respectWhitespace) {
      nodeText = nodeText.trim();
    }

    return nodeText;
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
