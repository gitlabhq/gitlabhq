import { shallowMount } from '@vue/test-utils';
import { mapComputed } from '~/vuex_shared/bindings';

describe('Binding utils', () => {
  describe('mapComputed', () => {
    const dummyComponent = {
      computed: {
        ...mapComputed('foo', 'bar', ['baz']),
      },
      render() {
        return null;
      },
    };
    it('returns an object with keys equal to the last fn parameter ', () => {
      const keyList = ['foo1', 'foo2'];
      const result = mapComputed('foo', 'bar', keyList);
      expect(Object.keys(result)).toEqual(keyList);
    });
    it('returned object has set and get function', () => {
      const result = mapComputed('foo', 'bar', ['baz']);
      expect(result.baz.set).toBeDefined();
      expect(result.baz.get).toBeDefined();
    });

    it('set function invokes $store.dispatch', () => {
      const context = shallowMount(dummyComponent, {
        mocks: {
          $store: {
            dispatch: jest.fn(),
          },
        },
      });
      context.vm.baz = 'a';
      expect(context.vm.$store.dispatch).toHaveBeenCalledWith('bar', { baz: 'a' });
    });
    it('get function returns $store.state[root][key]', () => {
      const context = shallowMount(dummyComponent, {
        mocks: {
          $store: {
            state: {
              foo: {
                baz: 1,
              },
            },
          },
        },
      });
      expect(context.vm.baz).toBe(1);
    });
  });
});
