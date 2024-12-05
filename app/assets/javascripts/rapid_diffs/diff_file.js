import { VIEWER_ADAPTERS } from './adapters';
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

export class DiffFile extends HTMLElement {
  diffElement;
  viewer;
  // intermediate state storage for adapters
  sink = {};

  adapterConfig = VIEWER_ADAPTERS;

  static findByFileHash(hash) {
    return document.querySelector(`diff-file#${hash}`);
  }

  static getAll() {
    return document.querySelectorAll('diff-file');
  }

  mount() {
    const [diffElement] = this.children;
    this.diffElement = diffElement;
    this.viewer = this.dataset.viewer;
    this.observeVisibility();
    this.diffElement.addEventListener('click', this.onClick.bind(this));
    this.trigger(events.MOUNTED);
  }

  trigger(event, ...args) {
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
        adapter.clicks?.[clickAction]?.call?.(this.adapterContext, event),
      );
    }
    this.trigger(events.CLICK, event);
  }

  get data() {
    const data = { ...this.dataset };
    // viewer is dynamic, should be accessed via this.viewer
    delete data.viewer;
    return data;
  }

  get adapterContext() {
    return {
      diffElement: this.diffElement,
      viewer: this.viewer,
      sink: this.sink,
      data: this.data,
      trigger: this.trigger,
    };
  }

  get adapters() {
    return this.adapterConfig[this.viewer] || [];
  }
}
