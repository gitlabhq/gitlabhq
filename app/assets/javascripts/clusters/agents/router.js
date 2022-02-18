import Vue from 'vue';
import VueRouter from 'vue-router';

Vue.use(VueRouter);

// Vue Router requires a component to render if the route matches, but since we're only using it for
// querystring handling, we'll create an empty component.
const EmptyRouterComponent = {
  render(createElement) {
    return createElement('div');
  },
};

export default () => {
  // Name and path here don't really matter since we're not rendering anything if the route matches.
  const routes = [{ path: '/', name: 'cluster_agents', component: EmptyRouterComponent }];
  return new VueRouter({
    mode: 'history',
    base: window.location.pathname,
    routes,
  });
};
