/* eslint-disable jest/valid-describe-callback, jest/no-disabled-tests, jest/no-export, jest/valid-title */
import { env, argv } from 'node:process';

const skipVue3 = env.VUE_VERSION === '3' && !argv.includes('--no-skip-vue3');

export class SkipReason {
  constructor({ name, reason, issue } = {}) {
    if (!name || !reason || !issue) {
      throw new Error(`Provide a name, reason and issue: new SkipReason({name,reason,issue})`);
    }
    this.name = name;
    this.reason = reason;
  }
  toString() {
    return skipVue3 ? `  [SKIPPED with Vue@3]: ${this.name} (${this.reason})` : this.name;
  }
}

export function describeSkipVue3(reason, ...args) {
  if (!(reason instanceof SkipReason)) {
    throw new Error('Please provide a proper SkipReason');
  }

  return skipVue3
    ? describe.skip(reason.toString(), ...args)
    : describe(reason.toString(), ...args);
}

export function itSkipVue3(reason, ...args) {
  if (!(reason instanceof SkipReason)) {
    throw new Error('Please provide a proper SkipReason');
  }

  return skipVue3 ? it.skip(reason.toString(), ...args) : it(reason.toString(), ...args);
}
