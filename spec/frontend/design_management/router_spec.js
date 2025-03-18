import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import App from '~/design_management/components/app.vue';
import DesignDetail from '~/design_management/pages/design/index.vue';
import Designs from '~/design_management/pages/index.vue';
import createRouter from '~/design_management/router';
import { DESIGNS_ROUTE_NAME, DESIGN_ROUTE_NAME } from '~/design_management/router/constants';
import '~/commons/bootstrap';
import { getMatchedComponents } from '~/lib/utils/vue3compat/vue_router';

let router;

async function factory(routeArg) {
  router = createRouter('/');
  if (routeArg !== undefined) {
    await router.push(routeArg);
  }

  return shallowMount(App, {
    router,
  });
}

describe('Design management router', () => {
  describe.each([['/'], [{ name: DESIGNS_ROUTE_NAME }]])('root route', (routeArg) => {
    it('pushes home component', async () => {
      await factory(routeArg);
      const components = getMatchedComponents(router, router.currentRoute.path);
      expect(components).toEqual([Designs]);
    });
  });

  describe.each([['/designs/1'], [{ name: DESIGN_ROUTE_NAME, params: { id: '1' } }]])(
    'designs detail route',
    (routeArg) => {
      it('pushes designs detail component', async () => {
        await factory(routeArg);
        await nextTick();

        const route = router.currentRoute;
        const matchedComponents = getMatchedComponents(router, route.path);
        const propsData = route.matched[0].props.default({ params: { id: '1' } });

        expect(matchedComponents).toEqual([DesignDetail]);
        expect(propsData).toEqual({ id: '1' });
      });
    },
  );
});
