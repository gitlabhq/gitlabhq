import $ from 'jquery';
import renderMath from './render_math';
import renderMermaid from './render_mermaid';
import syntaxHighlight from './syntax_highlight';

// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
$.fn.renderGFM = function renderGFM() {
  syntaxHighlight(this.find('.js-syntax-highlight'));
  renderMath(this.find('.js-render-math'));
  renderMermaid(this.find('.js-render-mermaid'));
  return this;
};

$(() => $('body').renderGFM());
