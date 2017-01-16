/* eslint-disable class-methods-use-this */

(() => {
  const gfmRules = {
    // Should have an entry for every filter in lib/banzai/pipeline/gfm_pipeline.rb,
    // in reverse order.
    // Should have test coverage in spec/features/copy_as_gfm_spec.rb.
    "InlineDiffFilter": {
      "span.idiff.addition": function(el, text) {
        return "{+" + text + "+}";
      },
      "span.idiff.deletion": function(el, text) {
        return "{-" + text + "-}";
      },
    },
    "TaskListFilter": {
      "input[type=checkbox].task-list-item-checkbox": function(el, text) {
        return '[' + (el.checked ? 'x' : ' ') + ']';
      }
    },
    "ReferenceFilter": {
      "a.gfm:not([data-link=true])": function(el, text) {
        return el.getAttribute('data-original') || text;
      },
    },
    "AutolinkFilter": {
      "a": function(el, text) {
        if (text != el.getAttribute("href")) {
          // Fall back to handler for MarkdownFilter
          return false;
        }

        return text;
      },
    },
    "TableOfContentsFilter": {
      "ul.section-nav": function(el, text) {
        return "[[_TOC_]]";
      },
    },
    "EmojiFilter": {
      "img.emoji": function(el, text) {
        return el.getAttribute("alt");
      },
    },
    "ImageLinkFilter": {
      "a.no-attachment-icon": function(el, text) {
        return text;
      },
    },
    "VideoLinkFilter": {
      ".video-container": function(el, text) {
        var videoEl = el.querySelector('video');
        if (!videoEl) {
          return false;
        }

        return CopyAsGFM.nodeToGFM(videoEl);
      },
      "video": function(el, text) {
        return "![" + el.getAttribute('data-title') + "](" + el.getAttribute("src") + ")";
      },
    },
    "MathFilter": {
      "pre.code.math[data-math-style='display']": function(el, text) {
        return "```math\n" + text.trim() + "\n```";
      },
      "code.code.math[data-math-style='inline']": function(el, text) {
        return "$`" + text + "`$";
      },
      "span.katex-display span.katex-mathml": function(el, text) {
        var mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) {
          return false;
        }

        return "```math\n" + CopyAsGFM.nodeToGFM(mathAnnotation)  + "\n```";
      },
      "span.katex-mathml": function(el, text) {
        var mathAnnotation = el.querySelector('annotation[encoding="application/x-tex"]');
        if (!mathAnnotation) {
          return false;
        }

        return "$`" + CopyAsGFM.nodeToGFM(mathAnnotation) + "`$";
      },
      "span.katex-html": function(el, text) {
        return "";
      },
      'annotation[encoding="application/x-tex"]': function(el, text) {
        return text.trim();
      }
    },
    "SyntaxHighlightFilter": {
      "pre.code.highlight": function(el, text) {
        var lang = el.getAttribute("lang");
        if (lang == "text") {
          lang = "";
        }
        return "```" + lang + "\n" + text.trim() + "\n```";
      },
      "pre > code": function(el, text) {
         // Don't wrap code blocks in ``
        return text;
      },
    },
    "MarkdownFilter": {
      "code": function(el, text) {
        var backtickCount = 1;
        var backtickMatch = text.match(/`+/);
        if (backtickMatch) {
          backtickCount = backtickMatch[0].length + 1;
        }

        var backticks = new Array(backtickCount + 1).join('`');
        var spaceOrNoSpace = backtickCount > 1 ? " " : "";

        return backticks + spaceOrNoSpace + text + spaceOrNoSpace + backticks;
      },
      "blockquote": function(el, text) {
        return text.trim().split('\n').map(function(s) { return ('> ' + s).trim(); }).join('\n');
      },
      "img": function(el, text) {
        return "![" + el.getAttribute("alt") + "](" + el.getAttribute("src") + ")";
      },
      "a.anchor": function(el, text) {
        return text;
      },
      "a": function(el, text) {
        return "[" + text + "](" + el.getAttribute("href") + ")";
      },
      "li": function(el, text) {
        var lines = text.trim().split('\n');
        var firstLine = '- ' + lines.shift();
        var nextLines = lines.map(function(s) { return ('  ' + s).replace(/\s+$/, ''); });

        return firstLine + '\n' + nextLines.join('\n');
      },
      "ul": function(el, text) {
        return text;
      },
      "ol": function(el, text) {
        return text.replace(/^- /mg, '1. ');
      },
      "h1": function(el, text) {
        return '# ' + text.trim();
      },
      "h2": function(el, text) {
        return '## ' + text.trim();
      },
      "h3": function(el, text) {
        return '### ' + text.trim();
      },
      "h4": function(el, text) {
        return '#### ' + text.trim();
      },
      "h5": function(el, text) {
        return '##### ' + text.trim();
      },
      "h6": function(el, text) {
        return '###### ' + text.trim();
      },
      "strong": function(el, text) {
        return '**' + text + '**';
      },
      "em": function(el, text) {
        return '_' + text + '_';
      },
      "del": function(el, text) {
        return '~~' + text + '~~';
      },
      "sup": function(el, text) {
        return '^' + text;
      },
      "hr": function(el, text) {
        return '-----';
      },
      "table": function(el, text) {
        var theadText = CopyAsGFM.nodeToGFM(el.querySelector('thead'));
        var tbodyText = CopyAsGFM.nodeToGFM(el.querySelector('tbody'));

        return theadText + tbodyText;
      },
      "thead": function(el, text) {
        var cells = _.map(el.querySelectorAll('th'), function(cell) {
          var chars = CopyAsGFM.nodeToGFM(cell).trim().length;

          var before = '';
          var after = '';
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

          var middle = new Array(chars + 1).join('-');

          return before + middle + after;
        });
        return text + '| ' + cells.join(' | ') + ' |';
      },
      "tr": function(el, text) {
        var cells = _.map(el.querySelectorAll('td, th'), function(cell) {
          return CopyAsGFM.nodeToGFM(cell).trim();
        });
        return '| ' + cells.join(' | ') + ' |';
      },
    }
  };

  class CopyAsGFM {
    constructor() {
      $(document).on('copy', '.md, .wiki', this.handleCopy.bind(this));
      $(document).on('paste', '.js-gfm-input', this.handlePaste.bind(this));
    }

    handleCopy(e) {
      var clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;

      if (!window.getSelection) return;

      var selection = window.getSelection();
      if (!selection.rangeCount || selection.rangeCount === 0) return;

      var selectedDocument = selection.getRangeAt(0).cloneContents();
      if (!selectedDocument) return;

      e.preventDefault();
      clipboardData.setData('text/plain', selectedDocument.textContent);

      var gfm = CopyAsGFM.nodeToGFM(selectedDocument);
      clipboardData.setData('text/x-gfm', gfm);
    }

    handlePaste(e) {
      var clipboardData = e.originalEvent.clipboardData;
      if (!clipboardData) return;
      
      var gfm = clipboardData.getData('text/x-gfm');
      if (!gfm) return;

      e.preventDefault();

      this.insertText(e.target, gfm);
    }

    insertText(target, text) {
      // Firefox doesn't support `document.execCommand('insertText', false, text);` on textareas
      var selectionStart = target.selectionStart;
      var selectionEnd = target.selectionEnd;
      var value = target.value;
      var textBefore = value.substring(0, selectionStart);
      var textAfter  = value.substring(selectionEnd, value.length);
      var newText = textBefore + text + textAfter;
      target.value = newText;
      target.selectionStart = target.selectionEnd = selectionStart + text.length;
    }

    static nodeToGFM(node) {
      if (node.nodeType == Node.TEXT_NODE) {
        return node.textContent;
      }

      var text = this.innerGFM(node);

      if (node.nodeType == Node.DOCUMENT_FRAGMENT_NODE) {
        return text;
      }

      for (var filter in gfmRules) {
        var rules = gfmRules[filter];

        for (var selector in rules) {
          var func = rules[selector];

          if (!node.matches(selector)) continue;

          var result = func(node, text);
          if (result === false) continue;

          return result;
        }
      }

      return text;
    }

    static innerGFM(parentNode) {
      var nodes = parentNode.childNodes;

      var clonedParentNode = parentNode.cloneNode(true);
      var clonedNodes = Array.prototype.slice.call(clonedParentNode.childNodes, 0);

      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        var clonedNode = clonedNodes[i];

        var text = this.nodeToGFM(node);
        clonedNode.parentNode.replaceChild(document.createTextNode(text), clonedNode);
      }

      return clonedParentNode.innerText || clonedParentNode.textContent;
    }
  }

  window.gl = window.gl || {};
  window.gl.CopyAsGFM = CopyAsGFM;

  new CopyAsGFM();
})();
