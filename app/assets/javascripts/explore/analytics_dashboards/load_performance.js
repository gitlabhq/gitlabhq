import { getPanelElement } from '~/lib/utils/panels';
import { performanceMarkAndMeasure } from '~/performance/utils';

/**
 * Sets `mark` now and, given a `start` mark, measures from it. Every load re-marks, so the
 * previous mark is cleared first: `performanceMarkAndMeasure` keeps an existing mark otherwise.
 * Synchronous, so the mark lands when the data does, even in a background tab.
 */
export const markLoadStep = ({ mark, measure, start }) => {
  performance.clearMarks(mark);
  performanceMarkAndMeasure({
    mark,
    measures: measure ? [{ name: measure, start }] : [],
    sync: true,
  });
};

// Whether any part of the panel is inside the visible part of the dashboard's scroll container.
const isInView = (el) => {
  const scroller = getPanelElement(el);
  const view = scroller ? scroller.getBoundingClientRect() : { top: 0, bottom: window.innerHeight };
  const { top, bottom } = el.getBoundingClientRect();

  return top < view.bottom && bottom >= view.top;
};

/**
 * Waits for the GLQL panels in view to load their first result (or fail), then calls `onDone`.
 *
 * Panels register when they mount or re-query, and settle when that result arrives. The panels
 * in view are only picked once every expected panel has registered, so the layout is in place.
 */
export class PanelsInViewTimer {
  #expectedPanels;

  #onDone;

  #registered = new Set();

  #settled = new Set();

  #inView = null;

  #finished = false;

  constructor({ expectedPanels, onDone }) {
    this.#expectedPanels = expectedPanels;
    this.#onDone = onDone;
  }

  register(el) {
    if (this.#finished) return;

    this.#settled.delete(el);
    this.#registered.add(el);
    this.#check();
  }

  settle(el) {
    if (this.#finished || !this.#registered.has(el)) return;

    this.#settled.add(el);
    this.#check();
  }

  cancel() {
    this.#finished = true;
  }

  #check() {
    if (this.#registered.size < this.#expectedPanels) return;

    if (!this.#inView) {
      const inView = [...this.#registered].filter(isInView);
      this.#inView = inView.length ? inView : [...this.#registered];
    }

    if (!this.#inView.every((el) => this.#settled.has(el))) return;

    this.#finished = true;
    this.#onDone();
  }
}
