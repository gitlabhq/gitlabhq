/* eslint-disable no-param-reassign, prefer-template, no-var, no-void, consistent-return */

import AccessorUtilities from './lib/utils/accessor';

export default class Autosave {
  constructor(field, key, resource) {
    this.field = field;
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.resource = resource;
    if (key.join != null) {
      key = key.join('/');
    }
    this.key = 'autosave/' + key;
    this.field.data('autosave', this);
    this.restore();
    this.field.on('input', () => this.save());
  }

  restore() {
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
  }

  save() {
    var text;
    text = this.field.val();

    if (this.isLocalStorageAvailable && (text != null ? text.length : void 0) > 0) {
      return window.localStorage.setItem(this.key, text);
    }

    return this.reset();
  }

  reset() {
    if (!this.isLocalStorageAvailable) return;

    return window.localStorage.removeItem(this.key);
  }
}
