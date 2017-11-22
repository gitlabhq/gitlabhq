import './render_math';
import './render_mermaid';

// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
$.fn.renderGFM = function renderGFM() {
  this.find('.js-syntax-highlight').syntaxHighlight();
  this.find('.js-render-math').renderMath();
  this.find('.js-render-mermaid').renderMermaid();
  return this;
};

$(() => $('body').renderGFM());
