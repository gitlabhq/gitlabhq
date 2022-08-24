function addBlameLink(containerSelector, linkClass) {
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
      const { blamePath } = document.querySelector('.line-numbers').dataset;
      const blameLink = document.createElement('a');
      blameLink.classList.add('file-line-blame');
      blameLink.href = `${blamePath}#L${lineNumber}`;

      const wrapper = document.createElement('div');
      wrapper.classList.add('line-links', 'diff-line-num');

      wrapper.appendChild(blameLink);
      wrapper.appendChild(lineLinkCopy);
      lineLink.replaceWith(wrapper);
    }
  });
}

export default addBlameLink;
