import { shallowMount } from '@vue/test-utils';
import { mapComputed } from '~/vuex_shared/bindings';

describe('Binding utils', () => {
  describe('mapComputed', () => {
    const defaultArgs = [['baz'], 'bar', 'foo'];

    const createDummy = (mapComputedArgs = defaultArgs) => ({
      computed: {
        ...mapComputed(...mapComputedArgs),
      },
      render() {
        return null;
      },
    });

    const mocks = {
      $store: {
        state: {
          baz: 2,
          foo: {
            baz: 1,
          },
        },
        getters: {
          getBaz: 'foo',
        },
        dispatch: jest.fn(),
      },
    };

    it('returns an object with keys equal to the first fn parameter ', () => {
      const keyList = ['foo1', 'foo2'];
      const result = mapComputed(keyList, 'foo', 'bar');
      expect(Object.keys(result)).toEqual(keyList);
    });

    it('returned object has set and get function', () => {
      const result = mapComputed(['baz'], 'foo', 'bar');
      expect(result.baz.set).toBeDefined();
      expect(result.baz.get).toBeDefined();
    });

    describe('set function', () => {
      it('invokes $store.dispatch', () => {
        const context = shallowMount(createDummy(), { mocks });
        context.vm.baz = 'a';
        expect(context.vm.$store.dispatch).toHaveBeenCalledWith('bar', { baz: 'a' });
      });
      it('uses updateFn in list object mode if updateFn exists', () => {
        const context = shallowMount(createDummy([[{ key: 'foo', updateFn: 'baz' }]]), { mocks });
        context.vm.foo = 'b';
        expect(context.vm.$store.dispatch).toHaveBeenCalledWith('baz', { foo: 'b' });
      });
      it('in  list object mode defaults to defaultUpdateFn if updateFn do not exists', () => {
        const context = shallowMount(createDummy([[{ key: 'foo' }], 'defaultFn']), { mocks });
        context.vm.foo = 'c';
        expect(context.vm.$store.dispatch).toHaveBeenCalledWith('defaultFn', { foo: 'c' });
      });
    });

    describe('get function', () => {
      it('if root is set returns $store.state[root][key]', () => {
        const context = shallowMount(createDummy(), { mocks });
        expect(context.vm.baz).toBe(mocks.$store.state.foo.baz);
      });

      it('if root is not set returns $store.state[key]', () => {
        const context = shallowMount(createDummy([['baz'], 'bar']), { mocks });
        expect(context.vm.baz).toBe(mocks.$store.state.baz);
      });

      it('when using getters it invoke the appropriate getter', () => {
        const context = shallowMount(createDummy([[{ getter: 'getBaz', key: 'baz' }]]), { mocks });
        expect(context.vm.baz).toBe(mocks.$store.getters.getBaz);
      });
    });
  });
});
