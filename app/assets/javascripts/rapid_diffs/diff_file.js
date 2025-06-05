/** @typedef {import('./app/index.js').RapidDiffsFacade} */
import { camelizeKeys } from '~/lib/utils/object_utils';
import { DIFF_FILE_MOUNTED } from './dom_events';
import * as events from './events';

const eventNames = Object.values(events);
const dataCacheKey = Symbol('data');

export class DiffFile extends HTMLElement {
  /** @param {RapidDiffsFacade} app */
  app;
  /** @type {Element} */
  diffElement;
  /** @type {Function} Dispatch event to adapters
   * @param {string} event - Event name
   * @param {...any} args - Payload
   */
  trigger;
  /** @type {Object} Storage for intermediate state used by adapters */
  sink = {};

  static findByFileHash(hash) {
    return document.querySelector(`diff-file[id="${hash}"]`);
  }

  static getAll() {
    return Array.from(document.querySelectorAll('diff-file'));
  }

  // connectedCallback() is called immediately when the tag appears in DOM
  // when we're streaming components their children might not be present at the moment this is called
  // that's why we manually call mount() from <diff-file-mounted> component, which is always a last child
  mount(app) {
    this.app = app;
    const [diffElement] = this.children;
    this.diffElement = diffElement;
    this.observeVisibility();
    this.trigger = this.#trigger.bind(this);
    this.trigger(events.MOUNTED);
    this.dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED, { bubbles: true }));
  }

  disconnectedCallback() {
    // app might be missing if the file was destroyed before mounting
    // for example: changing view settings in the middle of the streaming
    if (this.app) this.unobserveVisibility();
    this.app = undefined;
    this.diffElement = undefined;
    this.sink = undefined;
    this.trigger = undefined;
  }

  #trigger(event, ...args) {
    if (!eventNames.includes(event))
      throw new Error(
        `Missing event declaration: ${event}. Did you forget to declare this in ~/rapid_diffs/events.js?`,
      );
    this.adapters.forEach((adapter) => adapter[event]?.call?.(this.adapterContext, ...args));
  }

  observeVisibility() {
    if (!this.adapters.some((adapter) => adapter[events.VISIBLE] || adapter[events.INVISIBLE]))
      return;
    this.app.observe(this);
  }

  unobserveVisibility() {
    this.app.unobserve(this);
  }

  // Delegated to Rapid Diffs App
  onVisible(entry) {
    this.trigger(events.VISIBLE, entry);
  }

  // Delegated to Rapid Diffs App
  onInvisible(entry) {
    this.trigger(events.INVISIBLE, entry);
  }

  // Delegated to Rapid Diffs App
  onClick(event) {
    const clickActionElement = event.target.closest('[data-click]');
    if (clickActionElement) {
      const clickAction = clickActionElement.dataset.click;
      this.adapters.forEach((adapter) =>
        adapter.clicks?.[clickAction]?.call?.(this.adapterContext, event, clickActionElement),
      );
    }
    this.trigger(events.CLICK, event);
  }

  selectFile() {
    this.scrollIntoView({ block: 'start' });
    setTimeout(() => {
      // with content-visibility we might get a layout shift which we have to account for
      // 1. first scroll: renders target file and neighbours, they receive proper dimensions
      // 2. layout updates: target file might jump up or down, depending on the intrinsic size mismatch in neighbours
      // 3. second scroll: layout is stable, we can now properly scroll the file into the viewport
      this.scrollIntoView({ block: 'start' });
    });
    // TODO: add outline for active file
  }

  focusFirstButton(options) {
    this.diffElement.querySelector('button').focus(options);
  }

  selfReplace(node) {
    // 'mount' is automagically called by the <diff-file-mounted> component inside the diff file
    this.replaceWith(node);
    node.focusFirstButton({ focusVisible: false });
  }

  get data() {
    if (!this[dataCacheKey]) this[dataCacheKey] = camelizeKeys(JSON.parse(this.dataset.fileData));
    return this[dataCacheKey];
  }

  get adapterContext() {
    return {
      appData: this.app.appData,
      diffElement: this.diffElement,
      sink: this.sink,
      data: this.data,
      trigger: this.trigger.bind(this),
      replaceWith: this.selfReplace.bind(this),
    };
  }

  get adapters() {
    return this.app.adapterConfig[this.data.viewer] || [];
  }
}
