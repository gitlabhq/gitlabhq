import { EXPANDED_LINES, INVISIBLE, MOUNTED, VISIBLE } from '~/rapid_diffs/adapter_events';
import { preventScrollToFragment } from '~/lib/utils/scroll_utils';
import { withLinkedFileUrlParams } from '~/rapid_diffs/utils/linked_file';

function scrollToLegacyFileFragment() {
  const { legacyFileFragment } = this.appData;
  if (!legacyFileFragment) return;
  const { fileHash, oldLine, newLine } = legacyFileFragment;
  if (fileHash !== this.id) return;
  if (!oldLine && !newLine) {
    this.selectFile();
    delete this.appData.legacyFileFragment;
    return;
  }
  const lineLink = this.diffElement.querySelector(
    `[data-position="old"] [data-line-number="${oldLine}"], [data-position="new"] [data-line-number="${newLine}"]`,
  );
  if (lineLink) lineLink.click();
}

function assignLinkedFileLink(lineNumber) {
  if (lineNumber.linked) return;
  const href = withLinkedFileUrlParams(new URL(window.location), {
    oldPath: this.data.oldPath,
    newPath: this.data.newPath,
  });
  href.hash = new URL(lineNumber.href).hash;
  // eslint-disable-next-line no-param-reassign
  lineNumber.href = href;
  // eslint-disable-next-line no-param-reassign
  lineNumber.linked = true;
}

// Performance optimization: we don't add linked file params to diff line links on the server
// because it would significantly increase HTML size
// Instead, we can modify these links either when idling or when a link is potentially visible
// Changing href causes reflow, thus we should avoid triggering this frequently
function handleAllLineLinks() {
  Array.from(this.diffElement.querySelectorAll('a[data-line-number]')).forEach(
    assignLinkedFileLink.bind(this),
  );
}

const getBody = (diffElement) => diffElement.querySelector('[data-file-body]');

export const lineLinkAdapter = {
  [VISIBLE]() {
    if (!this.sink.lineLinksHandled) {
      handleAllLineLinks.call(this);
      this.sink.lineLinksHandled = true;
    }
    getBody(this.diffElement).addEventListener('click', preventScrollToFragment);
  },
  [INVISIBLE]() {
    getBody(this.diffElement).removeEventListener('click', preventScrollToFragment);
  },
  [MOUNTED]() {
    requestIdleCallback(handleAllLineLinks.bind(this));
    scrollToLegacyFileFragment.call(this);
  },
  [EXPANDED_LINES]() {
    handleAllLineLinks.call(this);
  },
};
