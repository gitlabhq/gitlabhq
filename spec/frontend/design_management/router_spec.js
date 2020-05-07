import { mount, createLocalVue } from '@vue/test-utils';
import VueRouter from 'vue-router';
import App from '~/design_management/components/app.vue';
import Designs from '~/design_management/pages/index.vue';
import DesignDetail from '~/design_management/pages/design/index.vue';
import createRouter from '~/design_management/router';
import {
  ROOT_ROUTE_NAME,
  DESIGNS_ROUTE_NAME,
  DESIGN_ROUTE_NAME,
} from '~/design_management/router/constants';
import '~/commons/bootstrap';

jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

describe('Design management router', () => {
  let vm;
  let router;

  function factory() {
    const localVue = createLocalVue();

    localVue.use(VueRouter);

    window.gon = { sprite_icons: '' };

    router = createRouter('/');

    vm = mount(App, {
      localVue,
      router,
      mocks: {
        $apollo: {
          queries: {
            designs: { loading: true },
            design: { loading: true },
            permissions: { loading: true },
          },
        },
      },
    });
  }

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    vm.destroy();

    router.app.$destroy();
    window.location.hash = '';
  });

  describe.each([['/'], [{ name: ROOT_ROUTE_NAME }]])('root route', pushArg => {
    it('pushes home component', () => {
      router.push(pushArg);

      expect(vm.find(Designs).exists()).toBe(true);
    });
  });

  describe.each([['/designs'], [{ name: DESIGNS_ROUTE_NAME }]])('designs route', pushArg => {
    it('pushes designs root component', () => {
      router.push(pushArg);

      expect(vm.find(Designs).exists()).toBe(true);
    });
  });

  describe.each([['/designs/1'], [{ name: DESIGN_ROUTE_NAME, params: { id: '1' } }]])(
    'designs detail route',
    pushArg => {
      it('pushes designs detail component', () => {
        router.push(pushArg);

        return vm.vm.$nextTick().then(() => {
          const detail = vm.find(DesignDetail);
          expect(detail.exists()).toBe(true);
          expect(detail.props('id')).toEqual('1');
        });
      });
    },
  );
});
