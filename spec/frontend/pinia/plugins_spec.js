import { defineStore, setActivePinia } from 'pinia';

describe('Pinia plugins', () => {
  describe('globalAccessorPlugin', () => {
    describe('with pinia instance from instance.js', () => {
      it('applies tryStore method to stores', () => {
        // eslint-disable-next-line global-require
        const { pinia } = require('~/pinia/instance');
        setActivePinia(pinia);

        const useStoreA = defineStore('instanceTestStoreA', {
          state: () => ({ value: 'A' }),
        });

        const useStoreB = defineStore('instanceTestStoreB', {
          state: () => ({ value: 'B' }),
          actions: {
            getStoreAValue() {
              return this.tryStore('instanceTestStoreA').value;
            },
          },
        });

        // Initialize both stores
        useStoreA();
        const storeB = useStoreB();

        // This will throw "tryStore is not a function" if pinia._a fix is not applied
        // because plugins would be deferred and never applied in compat mode
        expect(typeof storeB.tryStore).toBe('function');
        expect(storeB.tryStore('instanceTestStoreA').value).toBe('A');
        expect(storeB.getStoreAValue()).toBe('A');
      });
    });
  });
});
