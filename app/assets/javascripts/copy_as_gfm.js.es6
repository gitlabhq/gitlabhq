/* eslint-disable class-methods-use-this */
/*jshint esversion: 6 */

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
      }
    },
    ReferenceFilter: {
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
        let videoEl = el.querySelector('video');
        if (!videoEl) return false;

        return CopyAsGFM.nodeToGFM(videoEl);
      },
      'video'(el, text) {
        return `![${el.dataset.title}](${el.getAttribute('src')})`;
      },
    },
    MathFilter: {
      'pre.code.math[data-math-style=display]'(el, text) {
        return '```math\n' + text.trim() + '\n```';
      },
      'code.code.math[data-math-style=inline]'(el, text) {
        return '$`' + text + '`$';
      },
      'span.katex-display span.katex-mathml'(el, text) {
        let mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) return false;

        return '```math\n' + CopyAsGFM.nodeToGFM(mathAnnotation)  + '\n```';
      },
      'span.katex-mathml'(el, text) {
        let mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) return false;

        return '$`' + CopyAsGFM.nodeToGFM(mathAnnotation) + '`$';
      },
      'span.katex-html'(el, text) {
        // We don't want to include the content of this element in the copied text.
        return '';
      },
      'annotation[encoding="application/x-tex"]'(el, text) {
        return text.trim();
      }
    },
    SyntaxHighlightFilter: {
      'pre.code.highlight'(el, text) {
        let lang = el.getAttribute('lang');
        if (lang === 'plaintext') {
          lang = '';
        }
        return '```' + lang + '\n' + text.trim() + '\n```';
      },
      'pre > code'(el, text) {
         // Don't wrap code blocks in ``
        return text;
      },
    },
    MarkdownFilter: {
      'code'(el, text) {
        let backtickCount = 1;
        let backtickMatch = text.match(/`+/);
        if (backtickMatch) {
          backtickCount = backtickMatch[0].length + 1;
        }

        let backticks = new Array(backtickCount + 1).join('`');
        let spaceOrNoSpace = backtickCount > 1 ? ' ' : '';

        return backticks + spaceOrNoSpace + text + spaceOrNoSpace + backticks;
      },
      'blockquote'(el, text) {
        return text.trim().split('\n').map((s) => `> ${s}`.trim()).join('\n');
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
        let lines = text.trim().split('\n');
        let firstLine = '- ' + lines.shift();
        // Add two spaces to the front of subsequent list items lines, or leave the line entirely blank.
        let nextLines = lines.map(function(s) {
          if (s.trim().length === 0) {
            return '';
          } else {
            return `  ${s}`;
          }
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
        let theadText = CopyAsGFM.nodeToGFM(el.querySelector('thead'));
        let tbodyText = CopyAsGFM.nodeToGFM(el.querySelector('tbody'));

        return theadText + tbodyText;
      },
      'thead'(el, text) {
        let cells = _.map(el.querySelectorAll('th'), function(cell) {
          let chars = CopyAsGFM.nodeToGFM(cell).trim().length;

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
          }

          chars = Math.max(chars, 0);

          let middle = new Array(chars + 1).join('-');

          return before + middle + after;
        });

        return text + `| ${cells.join(' | ')} |`;
      },
      'tr'(el, text) {
        let cells = _.map(el.querySelectorAll('td, th'), function(cell) {
          return CopyAsGFM.nodeToGFM(cell).trim();
        });
        return `| ${cells.join(' | ')} |`;
      },
    }
  };

  class CopyAsGFM {
    constructor() {
      $(document).on('copy', '.md, .wiki', this.handleCopy.bind(this));
      $(document).on('paste', '.js-gfm-input', this.handlePaste.bind(this));
    }

    handleCopy(e) {
      let clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;

      let documentFragment = CopyAsGFM.getSelectedFragment();
      if (!documentFragment) return;

      e.preventDefault();
      clipboardData.setData('text/plain', documentFragment.textContent);

      let gfm = CopyAsGFM.nodeToGFM(documentFragment);
      clipboardData.setData('text/x-gfm', gfm);
    }

    handlePaste(e) {
      let clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;

      let gfm = clipboardData.getData('text/x-gfm');
      if (!gfm) return;

      e.preventDefault();

      CopyAsGFM.insertText(e.target, gfm);
    }

    static getSelectedFragment() {
      if (!window.getSelection) return null;

      let selection = window.getSelection();
      if (!selection.rangeCount || selection.rangeCount === 0) return null;

      let documentFragment = selection.getRangeAt(0).cloneContents();
      if (!documentFragment) return null;

      if (documentFragment.textContent.length === 0) return null;

      return documentFragment;
    }

    static insertText(target, text) {
      // Firefox doesn't support `document.execCommand('insertText', false, text)` on textareas

      let selectionStart = target.selectionStart;
      let selectionEnd = target.selectionEnd;
      let value = target.value;

      let textBefore = value.substring(0, selectionStart);
      let textAfter  = value.substring(selectionEnd, value.length);
      let newText = textBefore + text + textAfter;

      target.value = newText;
      target.selectionStart = target.selectionEnd = selectionStart + text.length;
    }

    static nodeToGFM(node) {
      if (node.nodeType === Node.TEXT_NODE) {
        return node.textContent;
      }

      let text = this.innerGFM(node);

      if (node.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
        return text;
      }

      for (let filter in gfmRules) {
        let rules = gfmRules[filter];

        for (let selector in rules) {
          let func = rules[selector];

          if (!CopyAsGFM.nodeMatchesSelector(node, selector)) continue;

          let result = func(node, text);
          if (result === false) continue;

          return result;
        }
      }

      return text;
    }

    static innerGFM(parentNode) {
      let nodes = parentNode.childNodes;

      let clonedParentNode = parentNode.cloneNode(true);
      let clonedNodes = Array.prototype.slice.call(clonedParentNode.childNodes, 0);

      for (let i = 0; i < nodes.length; i++) {
        let node = nodes[i];
        let clonedNode = clonedNodes[i];

        let text = this.nodeToGFM(node);
        
        // `clonedNode.replaceWith(text)` is not yet widely supported
        clonedNode.parentNode.replaceChild(document.createTextNode(text), clonedNode);
      }

      return clonedParentNode.innerText || clonedParentNode.textContent;
    }

    static nodeMatchesSelector(node, selector) {
      let matches = Element.prototype.matches ||
        Element.prototype.matchesSelector ||
        Element.prototype.mozMatchesSelector ||
        Element.prototype.msMatchesSelector ||
        Element.prototype.oMatchesSelector ||
        Element.prototype.webkitMatchesSelector;

      if (matches) {
        return matches.call(node, selector);
      }

      // IE11 doesn't support `node.matches(selector)`

      let parentNode = node.parentNode;
      if (!parentNode) {
        parentNode = document.createElement('div');
        node = node.cloneNode(true);
        parentNode.appendChild(node);
      }

      let matchingNodes = parentNode.querySelectorAll(selector);
      return Array.prototype.indexOf.call(matchingNodes, node) !== -1;
    }
  }

  window.gl = window.gl || {};
  window.gl.CopyAsGFM = CopyAsGFM;

  new CopyAsGFM();
})();
