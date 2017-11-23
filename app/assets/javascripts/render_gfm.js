import renderMath from './render_math';

// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math
//
$.fn.renderGFM = function renderGFM() {
  this.find('.js-syntax-highlight').syntaxHighlight();
  renderMath(this.find('.js-render-math'));
  return this;
};

$(() => $('body').renderGFM());
