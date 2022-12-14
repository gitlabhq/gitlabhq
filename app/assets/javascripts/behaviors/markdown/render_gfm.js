import $ from 'jquery';
import syntaxHighlight from '~/syntax_highlight';
import highlightCurrentUser from './highlight_current_user';
import { renderKroki } from './render_kroki';
import renderMath from './render_math';
import renderSandboxedMermaid from './render_sandboxed_mermaid';
import renderMetrics from './render_metrics';
import renderObservability from './render_observability';
import { renderJSONTable } from './render_json_table';

// Render GitLab flavoured Markdown
//
// Delegates to syntax highlight and render math & mermaid diagrams.
//
$.fn.renderGFM = function renderGFM() {
  syntaxHighlight(this.find('.js-syntax-highlight').get());
  renderKroki(this.find('.js-render-kroki[hidden]').get());
  renderMath(this.find('.js-render-math'));
  renderSandboxedMermaid(this.find('.js-render-mermaid').get());
  renderJSONTable(
    Array.from(this.find('[lang="json"][data-lang-params="table"]').get()).map((e) => e.parentNode),
  );

  highlightCurrentUser(this.find('.gfm-project_member').get());

  const issuablePopoverElements = this.find('.gfm-issue, .gfm-merge_request').get();
  if (issuablePopoverElements.length) {
    import(/* webpackChunkName: 'IssuablePopoverBundle' */ '~/issuable/popover')
      .then(({ default: initIssuablePopovers }) => {
        initIssuablePopovers(issuablePopoverElements);
      })
      .catch(() => {});
  }

  renderMetrics(this.find('.js-render-metrics').get());
  renderObservability(this.find('.js-render-observability').get());
  return this;
};

$(() => {
  window.requestIdleCallback(
    () => {
      $('body').renderGFM();
    },
    { timeout: 500 },
  );
});
