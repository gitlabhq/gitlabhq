import syntaxHighlight from '~/syntax_highlight';
import highlightCurrentUser from './highlight_current_user';
import { renderKroki } from './render_kroki';
import renderMath from './render_math';
import renderSandboxedMermaid from './render_sandboxed_mermaid';
import renderIframe from './render_iframe';
import { renderGlql } from './render_glql';
import { renderJSONTable, renderJSONTableHTML } from './render_json_table';
import { addAriaLabels } from './accessibility';
import { renderImageLightbox } from './render_image_lightbox';

function initPopovers(elements) {
  if (!elements.length) return;
  import(/* webpackChunkName: 'IssuablePopoverBundle' */ '~/issuable/popover')
    .then(({ default: initIssuablePopovers }) => {
      initIssuablePopovers(elements);
    })
    .catch(() => {});
}

// Render GitLab Flavored Markdown
export function renderGFM(element) {
  if (!element) {
    return;
  }

  function arrayFromAll(selector) {
    return Array.from(element.querySelectorAll(selector));
  }

  const highlightEls = arrayFromAll('.js-syntax-highlight');
  const krokiEls = arrayFromAll('.js-render-kroki[hidden]');
  const mathEls = arrayFromAll('.js-render-math');
  const mermaidEls = arrayFromAll('.js-render-mermaid');
  const iframeEls = arrayFromAll('.js-render-iframe');
  const tableEls = arrayFromAll('[data-canonical-lang="json"][data-lang-params~="table"]');
  const tableHTMLEls = arrayFromAll('table[data-table-fields]');
  const glqlEls = arrayFromAll('[data-canonical-lang="glql"], .language-glql');
  const userEls = arrayFromAll('.gfm-project_member');
  const popoverEls = arrayFromAll(
    '.gfm-issue, .gfm-work_item, .gfm-merge_request, .gfm-epic, .gfm-milestone',
  );
  const taskListCheckboxEls = arrayFromAll('.task-list-item-checkbox');
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const imageEls = arrayFromAll('a>img');

  syntaxHighlight(highlightEls);
  renderKroki(krokiEls);
  renderMath(mathEls);
  renderSandboxedMermaid(mermaidEls);
  renderIframe(iframeEls);
  renderJSONTable(tableEls.map((e) => e.parentNode));
  renderJSONTableHTML(tableHTMLEls);
  highlightCurrentUser(userEls);
  initPopovers(popoverEls);
  addAriaLabels(taskListCheckboxEls);
  renderGlql(glqlEls);
  renderImageLightbox(imageEls, element);
}
