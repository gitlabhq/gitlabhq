import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import CloseButton from '~/design_management/components/toolbar/close_button.vue';

describe('Design management toolbar close button', () => {
  Vue.use(VueRouter);

  const router = new VueRouter({
    routes: [
      { path: '/', name: 'workItemList', component: { template: '<div>Designs</div>' } },
      { path: '/designs', name: 'designs', component: { template: '<div>Design detail</div>' } },
    ],
    mode: 'history',
  });

  let wrapper;

  function createComponent() {
    wrapper = mount(CloseButton, {
      router,
    });
  }

  it('links back to designs list', () => {
    createComponent();

    expect(wrapper.findComponent(GlButton).attributes().href).toEqual('/designs');
  });
});
