import { parseBoolean } from '~/lib/utils/common_utils';
import AccessorUtilities from './lib/utils/accessor';

export default class Autosave {
  // eslint-disable-next-line max-params
  constructor(field, key, fallbackKey, lockVersion) {
    this.field = field;
    this.type = this.field.getAttribute('type');
    this.isLocalStorageAvailable = AccessorUtilities.canUseLocalStorage();
    this.key = Array.isArray(key) ? `autosave/${key.join('/')}` : `autosave/${key}`;
    this.fallbackKey = fallbackKey;
    this.lockVersionKey = `${this.key}/lockVersion`;
    this.lockVersion = lockVersion;
    this.restore();
    this.saveAction = this.save.bind(this);
    // used by app/assets/javascripts/deprecated_notes.js
    this.field.$autosave = this;
    this.field.addEventListener('input', this.saveAction);
  }

  restore() {
    if (!this.isLocalStorageAvailable) return;
    const text = window.localStorage.getItem(this.key);
    const fallbackText = window.localStorage.getItem(this.fallbackKey);
    const newValue = text || fallbackText;

    if (newValue == null) return;

    let originalValue = this.field.value;
    if (this.type === 'checkbox') {
      originalValue = this.field.checked;
      this.field.checked = parseBoolean(newValue);
    } else {
      this.field.value = newValue;
    }

    if (originalValue === newValue) return;
    this.triggerInputEvents();
  }

  triggerInputEvents() {
    // trigger events so @input, @change and v-model trigger in Vue components
    const inputEvent = new Event('input', { bubbles: true, cancelable: false });
    const changeEvent = new Event('change', { bubbles: true, cancelable: false });
    this.field.dispatchEvent(inputEvent);
    this.field.dispatchEvent(changeEvent);
  }

  getSavedLockVersion() {
    if (!this.isLocalStorageAvailable) return undefined;
    return window.localStorage.getItem(this.lockVersionKey);
  }

  save() {
    const value = this.type === 'checkbox' ? this.field.checked : this.field.value;

    if (this.isLocalStorageAvailable && value) {
      if (this.fallbackKey) {
        window.localStorage.setItem(this.fallbackKey, value);
      }
      if (this.lockVersion !== undefined) {
        window.localStorage.setItem(this.lockVersionKey, this.lockVersion);
      }
      return window.localStorage.setItem(this.key, value);
    }

    return this.reset();
  }

  reset() {
    if (!this.isLocalStorageAvailable) return undefined;

    window.localStorage.removeItem(this.lockVersionKey);
    window.localStorage.removeItem(this.fallbackKey);
    return window.localStorage.removeItem(this.key);
  }

  dispose() {
    delete this.field.$autosave;
    this.field.removeEventListener('input', this.saveAction);
  }
}
