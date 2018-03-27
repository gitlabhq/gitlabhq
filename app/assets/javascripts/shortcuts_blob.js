import Mousetrap from 'mousetrap';
import { getLocationHash, visitUrl } from './lib/utils/url_utility';
import Shortcuts from './shortcuts';

const defaults = {
  skipResetBindings: false,
  fileBlobPermalinkUrl: null,
};

export default class ShortcutsBlob extends Shortcuts {
  constructor(opts) {
    const options = Object.assign({}, defaults, opts);
    super(options.skipResetBindings);
    this.options = options;

    Mousetrap.bind('y', this.moveToFilePermalink.bind(this));
  }

  moveToFilePermalink() {
    if (this.options.fileBlobPermalinkUrl) {
      const hash = getLocationHash();
      const hashUrlString = hash ? `#${hash}` : '';
      visitUrl(`${this.options.fileBlobPermalinkUrl}${hashUrlString}`);
    }
  }
}
