import { __ } from '~/locale';

export default class Counter {
  #n = 0;
  max;

  constructor(maxVal = 20) {
    this.max = maxVal;
  }

  increment() {
    if (this.#n >= this.max) {
      throw new Error(__('Counter exceeded max value'));
    }

    this.#n += 1;
    return this.#n;
  }

  reset() {
    this.#n = 0;
  }

  get value() {
    return this.#n;
  }
}
