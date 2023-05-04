import { mount } from '@vue/test-utils';
import { ErrorWithStack } from 'jest-util';

function installConsoleHandler(method) {
  const originalHandler = global.console[method];

  global.console[method] = function throwableHandler(...args) {
    if (args[0]?.includes('Invalid prop') || args[0]?.includes('Missing required prop')) {
      throw new ErrorWithStack(
        `Unexpected call of console.${method}() with:\n\n${args.join(', ')}`,
        this[method],
      );
    }

    originalHandler.apply(this, args);
  };

  return function restore() {
    global.console[method] = originalHandler;
  };
}

export function assertProps(Component, props, extraMountArgs = {}) {
  const [restoreError, restoreWarn] = [
    installConsoleHandler('error'),
    installConsoleHandler('warn'),
  ];
  const ComponentWithoutRenderFn = {
    ...Component,
    render() {
      return '';
    },
  };

  try {
    mount(ComponentWithoutRenderFn, { propsData: props, ...extraMountArgs });
  } finally {
    restoreError();
    restoreWarn();
  }
}
