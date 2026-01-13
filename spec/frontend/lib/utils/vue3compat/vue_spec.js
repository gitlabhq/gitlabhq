import Vue from 'vue';

describe('Vue.js 3 compat specific behavior', () => {
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
});
