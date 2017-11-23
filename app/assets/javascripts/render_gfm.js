import renderMath from './render_math';
<<<<<<< HEAD
import renderMermaid from './render_mermaid';
=======
>>>>>>> origin/master

// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
$.fn.renderGFM = function renderGFM() {
  this.find('.js-syntax-highlight').syntaxHighlight();
  renderMath(this.find('.js-render-math'));
<<<<<<< HEAD
  renderMermaid(this.find('.js-render-mermaid'));
=======
>>>>>>> origin/master
  return this;
};

$(() => $('body').renderGFM());
