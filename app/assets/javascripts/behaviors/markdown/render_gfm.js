import syntaxHighlight from '~/syntax_highlight';
import highlightCurrentUser from './highlight_current_user';
import { renderKroki } from './render_kroki';
import renderMath from './render_math';
import renderSandboxedMermaid from './render_sandboxed_mermaid';
import { renderGlql } from './render_glql';
import { renderJSONTable, renderJSONTableHTML } from './render_json_table';

function initPopovers(elements) {
  if (!elements.length) return;
  import(/* webpackChunkName: 'IssuablePopoverBundle' */ 'ee_else_ce/issuable/popover')
    .then(({ default: initIssuablePopovers }) => {
      initIssuablePopovers(elements);
    })
    .catch(() => {});
}

// Render GitLab flavored Markdown
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
    tableHTMLEls,
    glqlEls,
    userEls,
    popoverEls,
  ] = [
    '.js-syntax-highlight',
    '.js-render-kroki[hidden]',
    '.js-render-math',
    '.js-render-mermaid',
    '[data-canonical-lang="json"][data-lang-params="table"]',
    'table[data-table-fields]',
    '[data-canonical-lang="glql"]',
    '.gfm-project_member',
    '.gfm-issue, .gfm-work_item, .gfm-merge_request, .gfm-epic, .gfm-milestone',
  ].map((selector) => Array.from(element.querySelectorAll(selector)));

  syntaxHighlight(highlightEls);
  renderKroki(krokiEls);
  renderMath(mathEls);
  renderSandboxedMermaid(mermaidEls);
  renderJSONTable(tableEls.map((e) => e.parentNode));
  renderJSONTableHTML(tableHTMLEls);
  highlightCurrentUser(userEls);
  initPopovers(popoverEls);

  if (gon?.features?.glqlIntegration) renderGlql(glqlEls.map((e) => e.parentNode));
}
