import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueRouter from 'vue-router';
import CloseButton from '~/work_items/components/design_management/design_preview/close_button.vue';

describe('Design management toolbar close button', () => {
  let wrapper;

  Vue.use(VueRouter);
  const router = new VueRouter({
    routes: [
      { path: '/', name: 'workItemList', component: { template: '<div>Work items list</div>' } },
      {
        path: '/workItem',
        name: 'workItem',
        component: { template: '<div>Work items detail</div>' },
      },
    ],
    mode: 'history',
  });

  const createComponent = () => {
    wrapper = mount(CloseButton, {
      router,
    });
  };

  it('links back to designs list', () => {
    createComponent();

    expect(wrapper.findComponent(GlButton).attributes().href).toEqual('/workItem');
  });
});
