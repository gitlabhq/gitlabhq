import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueRouter from 'vue-router';
import waitForPromises from 'helpers/wait_for_promises';
import CloseButton from '~/design_management/components/toolbar/close_button.vue';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';

Vue.use(VueRouter);
const router = new VueRouter();

const RouterLinkStub = {
  props: {
    to: {
      type: Object,
    },
  },
  render(createElement) {
    return createElement('button', {}, this.$slots.default);
  },
};

describe('Design management toolbar close button', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(CloseButton, {
      router,
      stubs: {
        'router-link': RouterLinkStub,
      },
    });
  }

  it('links back to designs list', async () => {
    createComponent();

    await waitForPromises();
    const link = wrapper.find('button');

    expect(link.props('to')).toEqual({
      name: DESIGNS_ROUTE_NAME,
      query: {
        version: undefined,
      },
    });
  });
});
