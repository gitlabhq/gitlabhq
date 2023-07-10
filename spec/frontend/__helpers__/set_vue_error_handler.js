import Vue from 'vue';

const modifiedInstances = [];

export function setVueErrorHandler({ instance, handler }) {
  if (Vue.version.startsWith('2')) {
    // only global handlers are supported
    const { config } = Vue;
    config.errorHandler = handler;
    return;
  }

  // eslint-disable-next-line no-param-reassign
  instance.$.appContext.config.errorHandler = handler;
  modifiedInstances.push(instance);
}

export function resetVueErrorHandler() {
  if (Vue.version.startsWith('2')) {
    const { config } = Vue;
    config.errorHandler = null;
    return;
  }

  modifiedInstances.forEach((instance) => {
    // eslint-disable-next-line no-param-reassign
    instance.$.appContext.config.errorHandler = null;
  });
  modifiedInstances.length = 0;
}
