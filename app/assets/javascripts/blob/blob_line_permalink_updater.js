import { getLocationHash } from '../lib/utils/url_utility';
import { getPageParamValue, getPageSearchString } from './utils';

const lineNumberRe = /^(L|LC)[0-9]+/;

const updateLineNumbersOnBlobPermalinks = (linksToUpdate) => {
  const hash = getLocationHash();
  if (hash && lineNumberRe.test(hash)) {
    const hashUrlString = `#${hash}`;

    [].concat(Array.prototype.slice.call(linksToUpdate)).forEach((permalinkButton) => {
      const baseHref =
        permalinkButton.dataset.originalHref ||
        (() => {
          const href = permalinkButton.getAttribute('href');
          // eslint-disable-next-line no-param-reassign
          permalinkButton.dataset.originalHref = href;
          return href;
        })();
      const lineNum = parseInt(hash.split('L')[1], 10);
      const page = getPageParamValue(lineNum);
      const searchString = getPageSearchString(baseHref, page);
      permalinkButton.setAttribute('href', `${baseHref}${searchString}${hashUrlString}`);
    });
  }
};

function BlobLinePermalinkUpdater(blobContentHolder, lineNumberSelector, elementsToUpdate) {
  if (!blobContentHolder) return;
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
