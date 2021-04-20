import Mousetrap from 'mousetrap';
import { keysFor, PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import {
  getLocationHash,
  updateHistory,
  urlIsDifferent,
  urlContainsSha,
  getShaFromUrl,
} from '~/lib/utils/url_utility';
import { updateRefPortionOfTitle } from '~/repository/utils/title';
import Shortcuts from './shortcuts';

const defaults = {
  skipResetBindings: false,
  fileBlobPermalinkUrl: null,
  fileBlobPermalinkUrlElement: null,
};

function eventHasModifierKeys(event) {
  // We ignore alt because I don't think alt clicks normally do anything special?
  return event.ctrlKey || event.metaKey || event.shiftKey;
}

export default class ShortcutsBlob extends Shortcuts {
  constructor(opts) {
    const options = { ...defaults, ...opts };
    super(options.skipResetBindings);
    this.options = options;

    this.shortcircuitPermalinkButton();

    Mousetrap.bind(keysFor(PROJECT_FILES_GO_TO_PERMALINK), this.moveToFilePermalink.bind(this));
  }

  moveToFilePermalink() {
    const permalink = this.options.fileBlobPermalinkUrl;

    if (permalink) {
      const hash = getLocationHash();
      const hashUrlString = hash ? `#${hash}` : '';

      if (urlIsDifferent(permalink)) {
        updateHistory({
          url: `${permalink}${hashUrlString}`,
          title: document.title,
        });
      }

      if (urlContainsSha({ url: permalink })) {
        updateRefPortionOfTitle(getShaFromUrl({ url: permalink }));
      }
    }
  }

  shortcircuitPermalinkButton() {
    const button = this.options.fileBlobPermalinkUrlElement;
    const handleButton = (e) => {
      if (!eventHasModifierKeys(e)) {
        e.preventDefault();
        this.moveToFilePermalink();
      }
    };

    if (button) {
      button.addEventListener('click', handleButton);
    }
  }
}
