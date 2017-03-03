/* eslint-disable class-methods-use-this, object-shorthand, no-unused-vars, no-use-before-define, no-new, max-len, no-restricted-syntax, guard-for-in, no-continue */
/* jshint esversion: 6 */

require('./lib/utils/common_utils');

(() => {
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
      'input[type=checkbox].task-list-item-checkbox'(el, text) {
        return `[${el.checked ? 'x' : ' '}]`;
      },
    },
    ReferenceFilter: {
      '.tooltip'(el, text) {
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
      'ul.section-nav'(el, text) {
        return '[[_TOC_]]';
      },
    },
    EmojiFilter: {
      'img.emoji'(el, text) {
        return el.getAttribute('alt');
      },
    },
    ImageLinkFilter: {
      'a.no-attachment-icon'(el, text) {
        return text;
      },
    },
    VideoLinkFilter: {
      '.video-container'(el, text) {
        const videoEl = el.querySelector('video');
        if (!videoEl) return false;

        return CopyAsGFM.nodeToGFM(videoEl);
      },
      'video'(el, text) {
        return `![${el.dataset.title}](${el.getAttribute('src')})`;
      },
    },
    MathFilter: {
      'pre.code.math[data-math-style=display]'(el, text) {
        return `\`\`\`math\n${text.trim()}\n\`\`\``;
      },
      'code.code.math[data-math-style=inline]'(el, text) {
        return `$\`${text}\`$`;
      },
      'span.katex-display span.katex-mathml'(el, text) {
        const mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) return false;

        return `\`\`\`math\n${CopyAsGFM.nodeToGFM(mathAnnotation)}\n\`\`\``;
      },
      'span.katex-mathml'(el, text) {
        const mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) return false;

        return `$\`${CopyAsGFM.nodeToGFM(mathAnnotation)}\`$`;
      },
      'span.katex-html'(el, text) {
        // We don't want to include the content of this element in the copied text.
        return '';
      },
      'annotation[encoding="application/x-tex"]'(el, text) {
        return text.trim();
      },
    },
    SanitizationFilter: {
      'a[name]:not([href]):empty'(el, text) {
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
      'sub, dt, dd, kbd, q, samp, var, ruby, rt, rp, abbr'(el, text) {
        const tag = el.nodeName.toLowerCase();
        return `<${tag}>${text}</${tag}>`;
      },
    },
    SyntaxHighlightFilter: {
      'pre.code.highlight'(el, t) {
        const text = t.trim();

        let lang = el.getAttribute('lang');
        if (lang === 'plaintext') {
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
      'br'(el, text) {
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

        return backticks + spaceOrNoSpace + text + spaceOrNoSpace + backticks;
      },
      'blockquote'(el, text) {
        return text.trim().split('\n').map(s => `> ${s}`.trim()).join('\n');
      },
      'img'(el, text) {
        return `![${el.getAttribute('alt')}](${el.getAttribute('src')})`;
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
      'hr'(el, text) {
        return '-----';
      },
      'table'(el, text) {
        const theadEl = el.querySelector('thead');
        const tbodyEl = el.querySelector('tbody');
        if (!theadEl || !tbodyEl) return false;

        const theadText = CopyAsGFM.nodeToGFM(theadEl);
        const tbodyText = CopyAsGFM.nodeToGFM(tbodyEl);

        return theadText + tbodyText;
      },
      'thead'(el, text) {
        const cells = _.map(el.querySelectorAll('th'), (cell) => {
          let chars = CopyAsGFM.nodeToGFM(cell).trim().length + 2;

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

        return `${text}|${cells.join('|')}|`;
      },
      'tr'(el, text) {
        const cells = _.map(el.querySelectorAll('td, th'), cell => CopyAsGFM.nodeToGFM(cell).trim());
        return `| ${cells.join(' | ')} |`;
      },
    },
  };

  class CopyAsGFM {
    constructor() {
      $(document).on('copy', '.md, .wiki', this.handleCopy);
      $(document).on('paste', '.js-gfm-input', this.handlePaste);
    }

    handleCopy(e) {
      const clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;

      const documentFragment = window.gl.utils.getSelectedFragment();
      if (!documentFragment) return;

      // If the documentFragment contains more than just Markdown, don't copy as GFM.
      if (documentFragment.querySelector('.md, .wiki')) return;

      e.preventDefault();
      clipboardData.setData('text/plain', documentFragment.textContent);

      const gfm = CopyAsGFM.nodeToGFM(documentFragment);
      clipboardData.setData('text/x-gfm', gfm);
    }

    handlePaste(e) {
      const clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;

      const gfm = clipboardData.getData('text/x-gfm');
      if (!gfm) return;

      e.preventDefault();

      window.gl.utils.insertText(e.target, gfm);
    }

    static nodeToGFM(node) {
      if (node.nodeType === Node.TEXT_NODE) {
        return node.textContent;
      }

      const text = this.innerGFM(node);

      if (node.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
        return text;
      }

      for (const filter in gfmRules) {
        const rules = gfmRules[filter];

        for (const selector in rules) {
          const func = rules[selector];

          if (!window.gl.utils.nodeMatchesSelector(node, selector)) continue;

          const result = func(node, text);
          if (result === false) continue;

          return result;
        }
      }

      return text;
    }

    static innerGFM(parentNode) {
      const nodes = parentNode.childNodes;

      const clonedParentNode = parentNode.cloneNode(true);
      const clonedNodes = Array.prototype.slice.call(clonedParentNode.childNodes, 0);

      for (let i = 0; i < nodes.length; i += 1) {
        const node = nodes[i];
        const clonedNode = clonedNodes[i];

        const text = this.nodeToGFM(node);

        // `clonedNode.replaceWith(text)` is not yet widely supported
        clonedNode.parentNode.replaceChild(document.createTextNode(text), clonedNode);
      }

      return clonedParentNode.innerText || clonedParentNode.textContent;
    }
  }

  window.gl = window.gl || {};
  window.gl.CopyAsGFM = CopyAsGFM;

  new CopyAsGFM();
})();
