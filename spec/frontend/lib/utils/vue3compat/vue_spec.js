/* eslint-disable vue/one-component-per-file */
import Vue, { nextTick } from 'vue';
import { ignoreConsoleMessages } from 'helpers/console_watcher';

// Detect Vue 3 mode by checking for Vue 3-specific property
const isVue3 = Boolean(Vue.createApp);

describe('Vue.js compat behavior', () => {
  /*
  Unfortunately, jest uses CommonJS version of Vue.js
  So in order for these tests to pass we need to patch vue.cjs.js
  But for main application to work - we need to apply same fixes to vue.runtime.esm-bundler.js

  As for now it is manual task to ensure patches in these two files provided via patch-package are in sync
  */
  it('respects provide/inject passed via parent option', () => {
    const PROVIDED_VALUE = 'DEMO';
    const vueApp = new Vue({
      provide: {
        providedValue: PROVIDED_VALUE,
      },
      render() {
        return null;
      },
    });

    const el = document.createElement('div');
    let injectedValue = null;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      parent: vueApp,
      inject: ['providedValue'],
      render() {
        injectedValue = this.providedValue;
        return null;
      },
    });

    expect(injectedValue).toBe(PROVIDED_VALUE);
  });

  describe('__GITLAB_VUE3_MIGRATION_MUTABLE_PROPS__', () => {
    // Vue 3: "Set operation on key X failed: target is readonly"
    // Vue 2: "Avoid mutating a prop directly"
    ignoreConsoleMessages([
      /Set operation on key .* failed: target is readonly/,
      /Avoid mutating a prop directly/,
    ]);
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
    });

    afterEach(() => {
      container.remove();
    });

    it('allows prop mutation when magic property is set', async () => {
      let capturedInstance;

      const Child = Vue.extend({
        props: { value: { type: String, required: true } },
        mounted() {
          capturedInstance = this;
        },
        render(h) {
          return h('div', this.value);
        },
      });

      const propsData = { value: 'initial' };
      Object.defineProperty(propsData, '__GITLAB_VUE3_MIGRATION_MUTABLE_PROPS__', {
        value: true,
        enumerable: true,
      });

      // eslint-disable-next-line no-new
      new Vue({
        el: container,
        render(h) {
          return h(Child, { props: propsData });
        },
      });

      await nextTick();

      // This should NOT throw in dev mode when magic prop is set
      expect(() => {
        capturedInstance.$props.value = 'mutated';
      }).not.toThrow();

      expect(capturedInstance.$props.value).toBe('mutated');
    });

    // This test only applies to Vue 3 where props are readonly by default
    // In Vue 2, props are always mutable (though not recommended)
    (isVue3 ? describe : describe.skip)('Vue 3 specific', () => {
      it('props remain readonly without magic property', async () => {
        let capturedInstance;

        const Child = Vue.extend({
          props: { value: { type: String, required: true } },
          mounted() {
            capturedInstance = this;
          },
          render(h) {
            return h('div', this.value);
          },
        });

        // eslint-disable-next-line no-new
        new Vue({
          el: container,
          render(h) {
            return h(Child, { props: { value: 'initial' } });
          },
        });

        await nextTick();

        // Without magic prop, $props should be readonly (mutation silently fails)
        const originalValue = capturedInstance.$props.value;
        capturedInstance.$props.value = 'mutated';

        // In readonly mode, the value should remain unchanged
        expect(capturedInstance.$props.value).toBe(originalValue);
      });
    });
  });
});
