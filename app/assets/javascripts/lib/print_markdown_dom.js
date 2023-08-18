function getPrintContent(target, ignoreSelectors) {
  const cloneDom = target.cloneNode(true);
  cloneDom.querySelectorAll('details').forEach((detail) => {
    detail.setAttribute('open', '');
  });

  if (Array.isArray(ignoreSelectors) && ignoreSelectors.length > 0) {
    cloneDom.querySelectorAll(ignoreSelectors.join(',')).forEach((ignoredNode) => {
      ignoredNode.remove();
    });
  }

  cloneDom.querySelectorAll('img').forEach((img) => {
    img.setAttribute('loading', 'eager');
  });

  return cloneDom.innerHTML;
}

function getTitleContent(title) {
  const titleElement = document.createElement('h2');
  titleElement.className = 'gl-mt-0 gl-mb-5';
  titleElement.innerText = title;
  return titleElement.outerHTML;
}

export default async function printMarkdownDom({
  target,
  title,
  ignoreSelectors = [],
  stylesheet = [],
}) {
  const printJS = (await import('print-js')).default;

  const printContent = getPrintContent(target, ignoreSelectors);

  const titleElement = title ? getTitleContent(title) : '';

  const markdownElement = `<div class="md">${printContent}</div>`;

  const printable = titleElement + markdownElement;

  printJS({
    printable,
    type: 'raw-html',
    documentTitle: title,
    scanStyles: false,
    css: stylesheet,
  });
}
