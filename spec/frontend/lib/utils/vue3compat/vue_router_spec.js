import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';

Vue.use(VueRouter);

describe('VueRouterCompat', () => {
  describe('$route.params normalization', () => {
    it('returns catch-all path params as a string via $route', async () => {
      const TestComponent = {
        template: '<div>{{ $route.params.pathMatch }}</div>',
      };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '*', component: TestComponent }],
      });

      await router.push('/foo/bar/baz');

      const wrapper = shallowMount(TestComponent, {
        router,
      });

      await nextTick();

      expect(wrapper.text()).toMatch(/^\/?foo\/bar\/baz$/);
    });

    it('returns repeatable params as joined string via $route', async () => {
      const TestComponent = {
        template: '<div>{{ $route.params.id }}</div>',
      };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/users/:id+', component: TestComponent }],
      });

      await router.push('/users/1/2/3');

      const wrapper = shallowMount(TestComponent, {
        router,
      });

      await nextTick();

      expect(wrapper.text()).toBe('1/2/3');
    });
  });

  describe('$route reactivity', () => {
    it('updates template when route changes', async () => {
      const TestComponent = {
        template: '<div>{{ $route.path }}</div>',
      };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/page1', component: TestComponent },
          { path: '/page2', component: TestComponent },
        ],
      });

      await router.push('/page1');

      const wrapper = shallowMount(TestComponent, {
        router,
      });

      await nextTick();
      expect(wrapper.text()).toBe('/page1');

      await router.push('/page2');
      await nextTick();

      expect(wrapper.text()).toBe('/page2');
    });
  });

  describe('router initialization', () => {
    it('creates a working router when no routes provided', () => {
      const router = new VueRouter({
        mode: 'abstract',
      });

      expect(router).toBeDefined();
      expect(router.currentRoute).toBeDefined();
    });

    it('currentRoute is available synchronously after creation', () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/', component: { template: '<div />' } }],
      });

      expect(router.currentRoute).toBeDefined();
      expect(router.currentRoute.path).toBe('/');
    });

    it('defaults to hash mode when mode is not specified', () => {
      const router = new VueRouter({
        routes: [{ path: '/', component: { template: '<div />' } }],
      });

      expect(router).toBeDefined();
      expect(router.currentRoute).toBeDefined();
    });
  });

  describe('catch-all route transformation', () => {
    it('transforms root-level * to catch-all pattern', async () => {
      const CatchAllComponent = { template: '<div>404</div>' };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/home', component: { template: '<div>home</div>' } },
          { path: '*', component: CatchAllComponent },
        ],
      });

      await router.push('/unknown/path');

      expect(router.currentRoute.matched.length).toBeGreaterThan(0);
    });

    it('handles nested routes with children', async () => {
      const ParentComponent = { template: '<div><router-view /></div>' };
      const ChildComponent = { template: '<div>child</div>' };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          {
            path: '/parent',
            component: ParentComponent,
            children: [{ path: 'child', component: ChildComponent }],
          },
        ],
      });

      await router.push('/parent/child');

      expect(router.currentRoute.path).toBe('/parent/child');
      expect(router.currentRoute.matched).toHaveLength(2);
    });

    it('handles nested catch-all in children', async () => {
      const ParentComponent = { template: '<div><router-view /></div>' };
      const CatchAllComponent = { template: '<div>catch all</div>' };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          {
            path: '/parent',
            component: ParentComponent,
            children: [{ path: '*', component: CatchAllComponent }],
          },
        ],
      });

      await router.push('/parent/anything');

      expect(router.currentRoute.matched).toHaveLength(2);
    });
  });

  describe('router modes', () => {
    it('supports abstract mode', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/test', component: { template: '<div />' } }],
      });

      await router.push('/test');

      expect(router.currentRoute.path).toBe('/test');
    });

    it('supports hash mode', () => {
      const router = new VueRouter({
        mode: 'hash',
        routes: [{ path: '/', component: { template: '<div />' } }],
      });

      expect(router).toBeDefined();
      expect(router.currentRoute).toBeDefined();
    });
  });

  describe('navigation methods', () => {
    it('push navigates to a new route', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/', component: { template: '<div />' } },
          { path: '/new', component: { template: '<div />' } },
        ],
      });

      await router.push('/new');

      expect(router.currentRoute.path).toBe('/new');
    });

    it('replace navigates without adding to history', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/', component: { template: '<div />' } },
          { path: '/replaced', component: { template: '<div />' } },
        ],
      });

      await router.replace('/replaced');

      expect(router.currentRoute.path).toBe('/replaced');
    });

    it('push with object parameter works', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/', component: { template: '<div />' } },
          { path: '/users/:id', name: 'user', component: { template: '<div />' } },
        ],
      });

      await router.push({ name: 'user', params: { id: '42' } });

      expect(router.currentRoute.params.id).toBe('42');
    });
  });

  describe('query and hash', () => {
    it('preserves query parameters', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/search', component: { template: '<div />' } }],
      });

      await router.push('/search?q=test&page=1');

      expect(router.currentRoute.query).toEqual({ q: 'test', page: '1' });
    });

    it('preserves hash', async () => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/page', component: { template: '<div />' } }],
      });

      await router.push('/page#section');

      expect(router.currentRoute.hash).toBe('#section');
    });
  });

  describe('$router availability', () => {
    it('$router is available in components and can navigate', async () => {
      let componentRouter = null;
      const TestComponent = {
        template: '<div>{{ $route.path }}</div>',
        mounted() {
          componentRouter = this.$router;
        },
      };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/', component: TestComponent },
          { path: '/target', component: TestComponent },
        ],
      });

      const wrapper = shallowMount(TestComponent, {
        router,
      });

      await nextTick();
      expect(wrapper.text()).toBe('/');

      await componentRouter.push('/target');
      await nextTick();

      expect(wrapper.text()).toBe('/target');
    });
  });

  describe('route matching', () => {
    it('matched array contains route records', async () => {
      const HomeComponent = { template: '<div>home</div>' };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [{ path: '/home', component: HomeComponent, name: 'home' }],
      });

      await router.push('/home');

      expect(router.currentRoute.matched).toHaveLength(1);
      expect(router.currentRoute.matched[0].components.default).toBe(HomeComponent);
    });

    it('matched array contains multiple records for nested routes', async () => {
      const ParentComponent = { template: '<div><router-view /></div>' };
      const ChildComponent = { template: '<div>child</div>' };

      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          {
            path: '/parent',
            component: ParentComponent,
            children: [{ path: 'child', component: ChildComponent }],
          },
        ],
      });

      await router.push('/parent/child');

      expect(router.currentRoute.matched).toHaveLength(2);
      expect(router.currentRoute.matched[0].components.default).toBe(ParentComponent);
      expect(router.currentRoute.matched[1].components.default).toBe(ChildComponent);
    });
  });
});
