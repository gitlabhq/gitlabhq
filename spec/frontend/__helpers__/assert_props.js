import { mount } from '@vue/test-utils';
import { ErrorWithStack } from 'jest-util';

export function assertProps(Component, props, extraMountArgs = {}) {
  const originalConsoleError = global.console.error;
  global.console.error = function error(...args) {
    throw new ErrorWithStack(
      `Unexpected call of console.error() with:\n\n${args.join(', ')}`,
      this.error,
    );
  };
  const ComponentWithoutRenderFn = {
    ...Component,
    render() {
      return '';
    },
  };

  try {
    mount(ComponentWithoutRenderFn, { propsData: props, ...extraMountArgs });
  } finally {
    global.console.error = originalConsoleError;
  }
}
