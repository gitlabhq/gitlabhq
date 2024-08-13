import { VIEWER_ADAPTERS } from './adapters';
// required for easier mocking in tests
import IntersectionObserver from './intersection_observer';

/** @module RapidDiffs */

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
  /** @type {diffElement} */
  diffElement;
  /** @type {viewer} */
  viewer;

  adapterConfig = VIEWER_ADAPTERS;

  constructor() {
    super();
    this.boundOnClick = this.onClick.bind(this);
  }

  mount() {
    const [diffElement] = this.children;
    this.diffElement = diffElement;
    this.viewer = this.dataset.viewer;
    sharedObserver.observe(this);
  }

  onVisible() {
    this.diffElement.addEventListener('click', this.boundOnClick);
    this.adapters.forEach((adapter) => adapter.onVisible?.call?.(this.adapterContext));
  }

  onInvisible() {
    this.adapters.forEach((adapter) => adapter.onInvisible?.call?.(this.adapterContext));
    this.diffElement.removeEventListener('click', this.boundOnClick);
  }

  onClick(event) {
    this.adapters.forEach((adapter) => adapter.onClick?.call?.(this.adapterContext, event));
  }

  /** @returns {adapterContext} */
  get adapterContext() {
    return {
      diffElement: this.diffElement,
      viewer: this.viewer,
    };
  }

  /** @returns {diffFileAdapter[]} */
  get adapters() {
    return this.adapterConfig[this.viewer];
  }
}
