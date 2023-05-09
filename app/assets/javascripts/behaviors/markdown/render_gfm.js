import syntaxHighlight from '~/syntax_highlight';
import highlightCurrentUser from './highlight_current_user';
import { renderKroki } from './render_kroki';
import renderMath from './render_math';
import renderSandboxedMermaid from './render_sandboxed_mermaid';
import renderMetrics from './render_metrics';
import renderObservability from './render_observability';
import { renderJSONTable } from './render_json_table';

function initPopovers(elements) {
  if (!elements.length) return;
  import(/* webpackChunkName: 'IssuablePopoverBundle' */ '~/issuable/popover')
    .then(({ default: initIssuablePopovers }) => {
      initIssuablePopovers(elements);
    })
    .catch(() => {});
}

// Render GitLab flavoured Markdown
export function renderGFM(element) {
  if (!element) {
    return;
  }

  const [
    highlightEls,
    krokiEls,
    mathEls,
    mermaidEls,
    tableEls,
    userEls,
    popoverEls,
    metricsEls,
    observabilityEls,
  ] = [
    '.js-syntax-highlight',
    '.js-render-kroki[hidden]',
    '.js-render-math',
    '.js-render-mermaid',
    '[lang="json"][data-lang-params="table"]',
    '.gfm-project_member',
    '.gfm-issue, .gfm-work_item, .gfm-merge_request',
    '.js-render-metrics',
    '.js-render-observability',
  ].map((selector) => Array.from(element.querySelectorAll(selector)));

  syntaxHighlight(highlightEls);
  renderKroki(krokiEls);
  renderMath(mathEls);
  renderSandboxedMermaid(mermaidEls);
  renderJSONTable(tableEls.map((e) => e.parentNode));
  highlightCurrentUser(userEls);
  if (!window.gon?.features?.removeMonitorMetrics) {
    renderMetrics(metricsEls);
  }
  renderObservability(observabilityEls);
  initPopovers(popoverEls);
}
