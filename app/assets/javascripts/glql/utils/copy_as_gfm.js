import { escape } from 'lodash-es';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import {
  DATA_COPY_DISPLAY_TYPES,
  DOM_COPY_DISPLAY_TYPES,
  DISPLAY_TYPES,
  FIELD_TYPES,
} from '../constants';
import { dimensionsOf, metricsOf, dimensionValue, labelWithParameter } from './chart_data';
import { formatBucketDate } from './date_bucket';
import { valueFormatterFor } from './value_format';

const escapeGfmText = (str) =>
  String(str)
    .replace(/[\\|<>`*~[\]_&$]/g, '\\$&')
    .replace(/[\r\n]+/g, ' ');

const escapeGfmParagraph = (str) =>
  escapeGfmText(str)
    .replace(/^[#+-]/, '\\$&')
    .replace(/^(\d+)([.)])/, '$1\\$2');

const dimensionFormatter = ({ parameters }) => {
  const granularity = parameters?.granularity;
  return granularity ? (value) => formatBucketDate(value, granularity, true) : (value) => value;
};

/**
 * Builds clipboard content (HTML table and GFM markdown table) from
 * structured data (nodes + fields), so "Copy contents" produces a
 * readable table instead of scraping the rendered DOM.
 */
export function buildClipboardContent(nodes, fields) {
  const dimensions = dimensionsOf(fields);
  const metrics = metricsOf(fields);
  const headers = [...dimensions, ...metrics].map(labelWithParameter);

  const formatDimensions = dimensions.map(dimensionFormatter);
  const formatMetrics = metrics.map(valueFormatterFor);

  const rows = nodes.map((node) => [
    ...dimensions.map((d, i) => formatDimensions[i](dimensionValue(node, d))),
    ...metrics.map((m, i) => formatMetrics[i](node[m.key] ?? 0)),
  ]);

  // Build GFM markdown table
  const mdHeader = `| ${headers.map(escapeGfmText).join(' | ')} |`;
  const mdSeparator = `| ${headers.map(() => '---').join(' | ')} |`;
  const mdRows = rows.map((row) => `| ${row.map(escapeGfmText).join(' | ')} |`);
  const text = [mdHeader, mdSeparator, ...mdRows].join('\n');

  // Build HTML table
  const htmlHeaders = headers.map((h) => `<th>${escape(h)}</th>`).join('');
  const htmlRows = rows
    .map((row) => `<tr>${row.map((cell) => `<td>${escape(cell)}</td>`).join('')}</tr>`)
    .join('');
  const html = `<table><thead><tr>${htmlHeaders}</tr></thead><tbody>${htmlRows}</tbody></table>`;

  return { html, text };
}

/**
 * Writes both HTML and plain text to the clipboard when in a secure context,
 * otherwise falls back to copying plain text only via the `copyToClipboard`
 * utility (which handles insecure contexts like `http://gdk.test`).
 */
export async function writeToClipboard(html, text) {
  if (window.isSecureContext && typeof ClipboardItem !== 'undefined') {
    const clipboardItem = new ClipboardItem({
      'text/plain': new Blob([text], { type: 'text/plain' }),
      'text/html': new Blob([html], { type: 'text/html' }),
    });
    // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
    await navigator.clipboard.write([clipboardItem]);
  } else {
    await copyToClipboard(text);
  }
}

/**
 * Copies the rendered DOM of a GLQL view. `label` is prepended as a heading for
 * views that render no label of their own inside the copied element.
 */
export async function copyGLQLNodeAsGFM(el, { label } = {}) {
  const transform = (e) => {
    [...e.querySelectorAll('time[title]')].forEach((time) => {
      // eslint-disable-next-line no-param-reassign
      time.textContent = time.title;
    });
  };

  const div = document.createElement('div');
  div.appendChild(el.cloneNode(true));
  transform(div);

  const html = label ? `<p>${escape(label)}</p>${div.innerHTML}` : div.innerHTML;
  const markdown = await CopyAsGFM.nodeToGFM(el);
  const text = label ? `${escapeGfmParagraph(label)}\n\n${markdown}` : markdown;

  await writeToClipboard(html, text);
}

// A stat renders its title only when the block configures one, so an unconfigured stat
// would copy as a bare number: the container heading sits outside the copy boundary.
const copyLabelFor = (config, fields) => {
  if (config?.display !== DISPLAY_TYPES.STAT) return undefined;

  // Mirrors the presenter, which stringifies any non-nullish title into a heading.
  const title = config?.displayConfig?.title;
  if (title != null && String(title) !== '') return undefined;

  return labelWithParameter(metricsOf(fields ?? [])[0]);
};

/**
 * Copies a GLQL view's contents to the clipboard. Charts copy from the query result,
 * since they render to SVG/canvas with nothing copyable in the DOM; every other display
 * copies its rendered DOM, which already carries its on-screen order and formatting.
 */
export async function copyGLQLContents({ config, data, fields, el }) {
  const display = config?.display;
  const hasStructuredFields = fields?.some(
    (field) => field.type === FIELD_TYPES.DIMENSION || field.type === FIELD_TYPES.METRIC,
  );

  if (DATA_COPY_DISPLAY_TYPES.has(display) && data?.nodes && hasStructuredFields) {
    const { html, text } = buildClipboardContent(data.nodes, fields);
    await writeToClipboard(html, text);
    return;
  }

  if (!DOM_COPY_DISPLAY_TYPES.has(display) && !DATA_COPY_DISPLAY_TYPES.has(display)) {
    throw new Error(`No copy strategy for GLQL display type "${display}"`);
  }

  await copyGLQLNodeAsGFM(el, { label: copyLabelFor(config, fields) });
}
