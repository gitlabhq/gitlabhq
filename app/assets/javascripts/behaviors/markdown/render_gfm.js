import $ from 'jquery';
import syntaxHighlight from '~/syntax_highlight';
import renderMath from './render_math';
import renderMermaid from './render_mermaid';
import renderMetrics from './render_metrics';
import highlightCurrentUser from './highlight_current_user';
import initUserPopovers from '../../user_popovers';
import initMRPopovers from '../../mr_popover';

// Render GitLab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
$.fn.renderGFM = function renderGFM() {
  syntaxHighlight(this.find('.js-syntax-highlight'));
  renderMath(this.find('.js-render-math'));
  renderMermaid(this.find('.js-render-mermaid'));
  highlightCurrentUser(this.find('.gfm-project_member').get());
  initUserPopovers(this.find('.gfm-project_member').get());
  initMRPopovers(this.find('.gfm-merge_request').get());
  renderMetrics(this.find('.js-render-metrics').get());
  return this;
};

$(() => $('body').renderGFM());
