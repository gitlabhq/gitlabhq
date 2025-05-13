/** @typedef {import('./app/index.js').RapidDiffsFacade} */
import { camelizeKeys } from '~/lib/utils/object_utils';
import { DIFF_FILE_MOUNTED } from './dom_events';
// required for easier mocking in tests
import IntersectionObserver from './intersection_observer';
import * as events from './events';

const eventNames = Object.values(events);

const sharedObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.onVisible();
    } else {
      entry.target.onInvisible();
    }
  });
});

const dataCacheKey = Symbol('data');

export class DiffFile extends HTMLElement {
  /** @param {RapidDiffsFacade} app */
  app;
  diffElement;
  // intermediate state storage for adapters
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
    this.onClickHandler = this.onClick.bind(this);
    this.diffElement.addEventListener('click', this.onClickHandler);
    this.trigger = this.#trigger.bind(this);
    this.trigger(events.MOUNTED);
    this.dispatchEvent(new CustomEvent(DIFF_FILE_MOUNTED, { bubbles: true }));
  }

  disconnectedCallback() {
    sharedObserver.unobserve(this);
    this.diffElement.removeEventListener('click', this.onClickHandler);
    this.app = null;
    this.sink = null;
    this.diffElement = null;
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
    sharedObserver.observe(this);
  }

  onVisible() {
    this.trigger(events.VISIBLE);
  }

  onInvisible() {
    this.trigger(events.INVISIBLE);
  }

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
      trigger: this.trigger,
    };
  }

  get adapters() {
    return this.app.adapterConfig[this.data.viewer] || [];
  }
}
