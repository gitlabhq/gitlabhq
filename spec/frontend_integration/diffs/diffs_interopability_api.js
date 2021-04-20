/**
 * This helper module contains the API expectation of the diff output HTML.
 *
 * This helps simulate what third-party HTML scrapers, such as Sourcegraph,
 * should be looking for.
 */
export const getDiffCodePart = (codeElement) => {
  const el = codeElement.closest('[data-interop-type]');

  return el.dataset.interopType === 'old' ? 'base' : 'head';
};

export const getCodeElementFromLineNumber = (codeView, line, part) => {
  const type = part === 'base' ? 'old' : 'new';

  const el = codeView.querySelector(`[data-interop-${type}-line="${line}"]`);

  return el ? el.querySelector('span.line') : null;
};

export const getLineNumberFromCodeElement = (codeElement) => {
  const el = codeElement.closest('[data-interop-line]');

  return parseInt(el.dataset.interopLine || '', 10);
};
