import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';
import createRouter from '~/kubernetes_dashboard/router/index';
import { PODS_ROUTE_PATH } from '~/kubernetes_dashboard/router/constants';
import App from '~/kubernetes_dashboard/pages/app.vue';
import PageTitle from '~/kubernetes_dashboard/components/page_title.vue';

Vue.use(VueRouter);

let wrapper;
let router;
const base = 'base/path';

const mountApp = async (route = PODS_ROUTE_PATH) => {
  await router.push(route);

  wrapper = shallowMount(App, {
    router,
    provide: {
      agent: {},
    },
  });
};

const findPageTitle = () => wrapper.findComponent(PageTitle);

describe('Kubernetes dashboard app component', () => {
  beforeEach(() => {
    router = createRouter({
      base,
    });
  });

  it(`sets the correct title for '${PODS_ROUTE_PATH}' path`, async () => {
    await mountApp();

    expect(findPageTitle().text()).toBe('Pods');
  });
});
