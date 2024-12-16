import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/merge_requests/reports/components/app.vue';
import routes from '~/merge_requests/reports/routes';

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const createComponent = () => {
    const router = new VueRouter({ mode: 'history', routes });
    wrapper = shallowMountExtended(App, { router, provide: { hasPolicies: false } });
  };

  it('should render sidebar navigation', () => {
    createComponent();
    expect(wrapper.findByText('Code quality').exists()).toBe(true);
  });
});
