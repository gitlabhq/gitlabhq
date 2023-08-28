import Vue from 'vue';
import VueRouter from 'vue-router';
import App from '~/packages_and_registries/dependency_proxy/app.vue';

Vue.use(VueRouter);

export default function createRouter(base) {
  const routes = [{ path: '/', name: 'dependencyProxyApp', component: App }];
  return new VueRouter({
    mode: 'history',
    base,
    routes,
  });
}
