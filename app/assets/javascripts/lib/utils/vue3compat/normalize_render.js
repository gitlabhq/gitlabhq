import Vue from 'vue';

export function normalizeRender(originalComponent) {
  if (Vue.version.startsWith('2')) {
    return originalComponent;
  }

  return {
    ...originalComponent,
    render(...args) {
      const result = originalComponent.render.call(this, ...args);
      if (Array.isArray(result) && result.length === 1) {
        return result[0];
      }

      return result;
    },
  };
}
