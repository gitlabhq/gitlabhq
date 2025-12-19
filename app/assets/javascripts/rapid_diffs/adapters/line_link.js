import { INVISIBLE, MOUNTED, VISIBLE } from '~/rapid_diffs/adapter_events';
import { preventScrollToFragment } from '~/lib/utils/scroll_utils';

function scrollToLegacyFileFragment() {
  const { legacyFileFragment } = this.appData;
  if (!legacyFileFragment) return;
  const { fileHash, oldLine, newLine } = legacyFileFragment;
  if (fileHash !== this.id) return;
  if (!oldLine && !newLine) {
    this.selectFile();
    return;
  }
  const lineLink = this.diffElement.querySelector(
    `[data-position="old"] [data-line-number="${oldLine}"], [data-position="new"] [data-line-number="${newLine}"]`,
  );
  if (lineLink) lineLink.click();
}

const getBody = (diffElement) => diffElement.querySelector('[data-file-body]');

export const lineLinkAdapter = {
  [VISIBLE]() {
    getBody(this.diffElement).addEventListener('click', preventScrollToFragment);
  },
  [INVISIBLE]() {
    getBody(this.diffElement).removeEventListener('click', preventScrollToFragment);
  },
  [MOUNTED]() {
    scrollToLegacyFileFragment.call(this);
  },
};
