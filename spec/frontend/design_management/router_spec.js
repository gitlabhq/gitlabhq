import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import App from '~/design_management/components/app.vue';
import DesignDetail from '~/design_management/pages/design/index.vue';
import Designs from '~/design_management/pages/index.vue';
import createRouter from '~/design_management/router';
import { DESIGNS_ROUTE_NAME, DESIGN_ROUTE_NAME } from '~/design_management/router/constants';
import '~/commons/bootstrap';

function factory(routeArg) {
  Vue.use(VueRouter);

  const router = createRouter('/');
  if (routeArg !== undefined) {
    router.push(routeArg);
  }

  return mount(App, {
    router,
    provide: { issueIid: '1' },
    stubs: { Toolbar: true },
    mocks: {
      $apollo: {
        queries: {
          designCollection: { loading: true },
          design: { loading: true },
          permissions: { loading: true },
        },
        mutate: jest.fn(),
      },
    },
  });
}

describe('Design management router', () => {
  describe.each([['/'], [{ name: DESIGNS_ROUTE_NAME }]])('root route', (routeArg) => {
    it('pushes home component', () => {
      const wrapper = factory(routeArg);

      expect(wrapper.findComponent(Designs).exists()).toBe(true);
    });
  });

  describe.each([['/designs/1'], [{ name: DESIGN_ROUTE_NAME, params: { id: '1' } }]])(
    'designs detail route',
    (routeArg) => {
      it('pushes designs detail component', () => {
        const wrapper = factory(routeArg);

        return nextTick().then(() => {
          const detail = wrapper.findComponent(DesignDetail);
          expect(detail.exists()).toBe(true);
          expect(detail.props('id')).toEqual('1');
        });
      });
    },
  );
});
