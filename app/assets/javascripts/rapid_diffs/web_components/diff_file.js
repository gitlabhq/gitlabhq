/** @typedef {import('../app').RapidDiffsFacade} */
import { camelizeKeys } from '~/lib/utils/object_utils';
import { findLineRow } from '~/rapid_diffs/utils/line_utils';
import { scrollPastCoveringElements } from '~/lib/utils/sticky';
import { DIFF_FILE_MOUNTED } from '../dom_events';
import { settledScrollIntoView } from '../utils/settled_scroll_into_view';
import * as events from '../adapter_events';

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
  _hookTeardowns = {
    [events.MOUNTED]: new Set(),
  };

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
    // eslint-disable-next-line no-underscore-dangle
    this.trigger = this._trigger.bind(this);
    this.trigger(events.MOUNTED, this.registerMountedTeardowns.bind(this));
    this.dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED, { bubbles: true }));
  }

  disconnectedCallback() {
    // eslint-disable-next-line no-underscore-dangle
    const mountedTeardowns = this._hookTeardowns[events.MOUNTED];
    mountedTeardowns.forEach((cb) => {
      cb();
    });
    mountedTeardowns.clear();
    // eslint-disable-next-line no-underscore-dangle
    this._hookTeardowns = undefined;
    // app might be missing if the file was destroyed before mounting
    // for example: changing view settings in the middle of the streaming
    if (this.app) this.unobserveVisibility();
    this.app = undefined;
    this.diffElement = undefined;
    this.sink = undefined;
    this.trigger = undefined;
  }

  // don't use private methods because...Safari
  _trigger(event, ...args) {
    if (!eventNames.includes(event))
      throw new Error(
        `Missing event declaration: ${event}. Did you forget to declare this in ~/rapid_diffs/adapter_events.js?`,
      );
    this.adapters.forEach((adapter) => adapter[event]?.call?.(this.adapterContext, ...args));
  }

  registerMountedTeardowns(callback) {
    // eslint-disable-next-line no-underscore-dangle
    this._hookTeardowns[events.MOUNTED].add(callback);
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
    settledScrollIntoView(this, this.closest('[data-rapid-diffs]'));
    // TODO: add outline for active file
  }

  async selectLine(oldLine, newLine) {
    this.trigger(events.EXPAND_FILE);
    const linePos = { old_line: oldLine, new_line: newLine };
    this.trigger(events.HIGHLIGHT_LINES, { start: linePos, end: linePos });
    const lineRow = findLineRow(this.diffElement, oldLine, newLine);
    if (lineRow) {
      await settledScrollIntoView(lineRow, this.closest('[data-rapid-diffs]'));
      scrollPastCoveringElements(lineRow);
    } else {
      this.selectFile();
    }
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
      id: this.id,
      selectFile: this.selectFile.bind(this),
      trigger: this.trigger.bind(this),
      replaceWith: this.selfReplace.bind(this),
    };
  }

  get adapters() {
    return this.app.adapterConfig[this.data.viewer] || [];
  }
}
