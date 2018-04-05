/* eslint-disable no-param-reassign, prefer-template, no-var, no-void, consistent-return */

import AccessorUtilities from './lib/utils/accessor';

export default class Autosave {
  constructor(field, key) {
    this.field = field;

    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    if (key.join != null) {
      key = key.join('/');
    }
    this.key = 'autosave/' + key;
    this.field.data('autosave', this);
    this.restore();
    this.field.on('input', () => this.save());
  }

  restore() {
    if (!this.isLocalStorageAvailable) return;
    if (!this.field.length) return;

    const text = window.localStorage.getItem(this.key);

    if ((text != null ? text.length : void 0) > 0) {
      this.field.val(text);
    }

    this.field.trigger('input');
    // v-model does not update with jQuery trigger
    // https://github.com/vuejs/vue/issues/2804#issuecomment-216968137
    const event = new Event('change', { bubbles: true, cancelable: false });
    const field = this.field.get(0);
    field.dispatchEvent(event);
  }

  save() {
    if (!this.field.length) return;

    const text = this.field.val();

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
