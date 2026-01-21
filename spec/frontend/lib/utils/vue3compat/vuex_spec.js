import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

Vue.use(Vuex);

describe('Vuex store inheritance via parent option', () => {
  it('child instance inherits $store from parent', () => {
    const store = new Vuex.Store({
      state: { count: 42 },
    });

    const parentEl = document.createElement('div');
    const parentApp = new Vue({
      el: parentEl,
      store,
      render() {
        return null;
      },
    });

    const childEl = document.createElement('div');
    let childStore = null;

    // eslint-disable-next-line no-new
    new Vue({
      el: childEl,
      parent: parentApp,
      mounted() {
        childStore = this.$store;
      },
      render() {
        return null;
      },
    });

    expect(childStore).toBe(store);
    expect(childStore.state.count).toBe(42);
  });
});
