/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-param-reassign, quotes, prefer-template, no-var, one-var, no-unused-vars, one-var-declaration-per-line, no-void, consistent-return, no-empty, max-len */
import AccessorUtilities from './lib/utils/accessor';

window.Autosave = (function() {
  function Autosave(field, key, resource) {
    this.field = field;
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.resource = resource;
    if (key.join != null) {
      key = key.join('/');
    }
    this.key = 'autosave/' + key;
    this.field.data('autosave', this);
    this.restore();
    this.field.on('input', (function(_this) {
      return function() {
        return _this.save();
      };
    })(this));
  }

  Autosave.prototype.restore = function() {
    var text;

    if (!this.isLocalStorageAvailable) return;

    text = window.localStorage.getItem(this.key);

    if ((text != null ? text.length : void 0) > 0) {
      this.field.val(text);
    }
    if (!this.resource && this.resource !== 'issue') {
      this.field.trigger('input');
    } else {
      // v-model does not update with jQuery trigger
      // https://github.com/vuejs/vue/issues/2804#issuecomment-216968137
      const event = new Event('change', { bubbles: true, cancelable: false });
      const field = this.field.get(0);
      if (field) {
        field.dispatchEvent(event);
      }
    }
  };

  Autosave.prototype.save = function() {
    var text;
    text = this.field.val();

    if (this.isLocalStorageAvailable && (text != null ? text.length : void 0) > 0) {
      return window.localStorage.setItem(this.key, text);
    }

    return this.reset();
  };

  Autosave.prototype.reset = function() {
    if (!this.isLocalStorageAvailable) return;

    return window.localStorage.removeItem(this.key);
  };

  return Autosave;
})();

export default window.Autosave;
