import { getPageParamValue, getPageSearchString } from './utils';

export function addBlameLink(containerSelector, linkClass) {
  const containerEl = document.querySelector(containerSelector);

  if (!containerEl) {
    return;
  }

  containerEl.addEventListener('mouseover', (e) => {
    const isLineLink = e.target.classList.contains(linkClass);
    if (isLineLink) {
      const lineLink = e.target;
      const lineLinkCopy = lineLink.cloneNode(true);
      lineLinkCopy.classList.remove(linkClass, 'diff-line-num');

      const { lineNumber } = lineLink.dataset;
      const blameLink = document.createElement('a');
      const { blamePath } = document.querySelector('.line-numbers').dataset;
      blameLink.classList.add('file-line-blame');
      const blamePerPage = document.querySelector('.js-per-page')?.dataset?.blamePerPage;
      const pageNumber = getPageParamValue(lineNumber, blamePerPage);
      const searchString = getPageSearchString(blamePath, pageNumber);

      blameLink.href = `${blamePath}${searchString}#L${lineNumber}`;

      const wrapper = document.createElement('div');
      wrapper.classList.add('line-links', 'diff-line-num');

      wrapper.appendChild(blameLink);
      wrapper.appendChild(lineLinkCopy);
      lineLink.replaceWith(wrapper);
    }
  });
}
