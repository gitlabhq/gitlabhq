import { mount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
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

function factory(routeArg) {
  const localVue = createLocalVue();
  localVue.use(VueRouter);

  window.gon = { sprite_icons: '' };

  const router = createRouter('/');
  if (routeArg !== undefined) {
    router.push(routeArg);
  }

  return mount(App, {
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

jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

describe('Design management router', () => {
  afterEach(() => {
    window.location.hash = '';
  });

  describe.each([['/'], [{ name: ROOT_ROUTE_NAME }]])('root route', routeArg => {
    it('pushes home component', () => {
      const wrapper = factory(routeArg);

      expect(wrapper.find(Designs).exists()).toBe(true);
    });
  });

  describe.each([['/designs'], [{ name: DESIGNS_ROUTE_NAME }]])('designs route', routeArg => {
    it('pushes designs root component', () => {
      const wrapper = factory(routeArg);

      expect(wrapper.find(Designs).exists()).toBe(true);
    });
  });

  describe.each([['/designs/1'], [{ name: DESIGN_ROUTE_NAME, params: { id: '1' } }]])(
    'designs detail route',
    routeArg => {
      it('pushes designs detail component', () => {
        const wrapper = factory(routeArg);

        return nextTick().then(() => {
          const detail = wrapper.find(DesignDetail);
          expect(detail.exists()).toBe(true);
          expect(detail.props('id')).toEqual('1');
        });
      });
    },
  );
});
