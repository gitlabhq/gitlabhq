/* global Mousetrap */
/* global Shortcuts */

require('./shortcuts');

const defaults = {
  skipResetBindings: false,
  fileBlobPermalinkUrl: null,
};

class ShortcutsBlob extends Shortcuts {
  constructor(opts) {
    const options = Object.assign({}, defaults, opts);
    super(options.skipResetBindings);
    this.options = options;

    Mousetrap.bind('y', this.moveToFilePermalink.bind(this));
  }

  moveToFilePermalink() {
    if (this.options.fileBlobPermalinkUrl) {
      const hash = gl.utils.getLocationHash();
      const hashUrlString = hash ? `#${hash}` : '';
      gl.utils.visitUrl(`${this.options.fileBlobPermalinkUrl}${hashUrlString}`);
    }
  }
}

module.exports = ShortcutsBlob;
