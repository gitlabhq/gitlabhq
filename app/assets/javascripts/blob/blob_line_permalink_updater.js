import { getLocationHash } from '../lib/utils/url_utility';

const lineNumberRe = /^L[0-9]+/;

const updateLineNumbersOnBlobPermalinks = (linksToUpdate) => {
  const hash = getLocationHash();
  if (hash && lineNumberRe.test(hash)) {
    const hashUrlString = `#${hash}`;

    [].concat(Array.prototype.slice.call(linksToUpdate)).forEach((permalinkButton) => {
      const baseHref = permalinkButton.getAttribute('data-original-href') || (() => {
        const href = permalinkButton.getAttribute('href');
        permalinkButton.setAttribute('data-original-href', href);
        return href;
      })();
      permalinkButton.setAttribute('href', `${baseHref}${hashUrlString}`);
    });
  }
};

function BlobLinePermalinkUpdater(blobContentHolder, lineNumberSelector, elementsToUpdate) {
  const updateBlameAndBlobPermalinkCb = () => {
    // Wait for the hash to update from the LineHighlighter callback
    setTimeout(() => {
      updateLineNumbersOnBlobPermalinks(elementsToUpdate);
    }, 0);
  };

  blobContentHolder.addEventListener('click', (e) => {
    if (e.target.matches(lineNumberSelector)) {
      updateBlameAndBlobPermalinkCb();
    }
  });
  updateBlameAndBlobPermalinkCb();
}

export default BlobLinePermalinkUpdater;
