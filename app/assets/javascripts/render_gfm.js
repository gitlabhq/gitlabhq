/* eslint-disable func-names, space-before-function-paren, consistent-return, no-var, no-else-return, prefer-arrow-callback, max-len */

// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
(function() {
  $.fn.renderGFM = function() {
    this.find('.js-syntax-highlight').syntaxHighlight();
    this.find('.js-render-math').renderMath();
    this.find('.js-render-mermaid').renderMermaid();
    return this;
  };

  $(() => $('body').renderGFM());
}).call(window);
